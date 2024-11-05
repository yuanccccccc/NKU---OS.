#include <default_pmm.h>
#include <defs.h>
#include <error.h>
#include <memlayout.h>
#include <mmu.h>
#include <pmm.h>
#include <sbi.h>
#include <stdio.h>
#include <string.h>
#include <swap.h>
#include <sync.h>
#include <vmm.h>
#include <riscv.h>

// 物理页数组的虚拟地址
struct Page *pages;
// 物理内存的页数
size_t npage = 0;
// 内核镜像映射在 VA=KERNBASE 和 PA=info.base
uint_t va_pa_offset;
// 在 RISC-V 中，内存从 0x80000000 开始
const size_t nbase = DRAM_BASE / PGSIZE;

// 引导时页目录的虚拟地址
pde_t *boot_pgdir = NULL;
// 引导时页目录的物理地址
uintptr_t boot_cr3;

// physical memory management
const struct pmm_manager *pmm_manager;

static void check_alloc_page(void);
static void check_pgdir(void);
static void check_boot_pgdir(void);
// init_pmm_manager - 初始化一个 pmm_manager 实例
static void init_pmm_manager(void)
{
    pmm_manager = &default_pmm_manager;
    cprintf("memory management: %s\n", pmm_manager->name);
    pmm_manager->init();
}

// init_memmap - 调用 pmm->init_memmap 来为空闲内存构建 Page 结构
static void init_memmap(struct Page *base, size_t n)
{
    pmm_manager->init_memmap(base, n);
}

// alloc_pages - 调用 pmm->alloc_pages 来分配连续的 n*PAGESIZE 内存
struct Page *alloc_pages(size_t n)
{
    struct Page *page = NULL;
    bool intr_flag;

    while (1)
    {
        local_intr_save(intr_flag);
        {
            page = pmm_manager->alloc_pages(n);
        }
        local_intr_restore(intr_flag);

        if (page != NULL || n > 1 || swap_init_ok == 0)
            break;

        extern struct mm_struct *check_mm_struct;
        // cprintf("page %x, call swap_out in alloc_pages %d\n",page, n);
        swap_out(check_mm_struct, n, 0);
    }
    // cprintf("n %d,get page %x, No %d in alloc_pages\n",n,page,(page-pages));
    return page;
}

// free_pages - 调用 pmm->free_pages 来释放连续的 n*PAGESIZE 内存
void free_pages(struct Page *base, size_t n)
{
    bool intr_flag;

    local_intr_save(intr_flag);
    {
        pmm_manager->free_pages(base, n);
    }
    local_intr_restore(intr_flag);
}

// nr_free_pages - 调用 pmm->nr_free_pages 来获取当前空闲内存的大小 (nr*PAGESIZE)
size_t nr_free_pages(void)
{
    size_t ret;
    bool intr_flag;
    local_intr_save(intr_flag);
    {
        ret = pmm_manager->nr_free_pages();
    }
    local_intr_restore(intr_flag);
    return ret;
}

/* page_init - 初始化物理内存管理 */
static void page_init(void)
{
    extern char kern_entry[];

    va_pa_offset = KERNBASE - 0x80200000;
    uint64_t mem_begin = KERNEL_BEGIN_PADDR;
    uint64_t mem_size = PHYSICAL_MEMORY_END - KERNEL_BEGIN_PADDR;
    uint64_t mem_end = PHYSICAL_MEMORY_END; // 硬编码取代 sbi_query_memory()接口
    cprintf("membegin %llx memend %llx mem_size %llx\n", mem_begin, mem_end, mem_size);
    cprintf("physcial memory map:\n");
    cprintf("  memory: 0x%08lx, [0x%08lx, 0x%08lx].\n", mem_size, mem_begin,
            mem_end - 1);
    uint64_t maxpa = mem_end;

    if (maxpa > KERNTOP)
    {
        maxpa = KERNTOP;
    }

    extern char end[];

    npage = maxpa / PGSIZE;
    // BBL 已将初始页表放在内核后的第一个可用页
    // 因此通过在 end 上添加额外的偏移量来避开它
    pages = (struct Page *)ROUNDUP((void *)end, PGSIZE);
    for (size_t i = 0; i < npage - nbase; i++)
    {
        SetPageReserved(pages + i);
    }

    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
    mem_begin = ROUNDUP(freemem, PGSIZE);
    mem_end = ROUNDDOWN(mem_end, PGSIZE);
    if (freemem < mem_end)
    {
        init_memmap(pa2page(mem_begin), (mem_end - mem_begin) / PGSIZE);
    }
}

static void enable_paging(void)
{
    write_csr(satp, (0x8000000000000000) | (boot_cr3 >> RISCV_PGSHIFT));
}

/**
 * @brief      设置并启用分页机制
 *
 * @param      pgdir  页目录
 * @param[in]  la     需要映射的线性地址
 * @param[in]  size   内存大小
 * @param[in]  pa     内存的物理地址
 * @param[in]  perm   内存的权限
 */
static void boot_map_segment(pde_t *pgdir, uintptr_t la, size_t size,
                             uintptr_t pa, uint32_t perm)
{
    assert(PGOFF(la) == PGOFF(pa));
    size_t n = ROUNDUP(size + PGOFF(la), PGSIZE) / PGSIZE;
    la = ROUNDDOWN(la, PGSIZE);
    pa = ROUNDDOWN(pa, PGSIZE);
    for (; n > 0; n--, la += PGSIZE, pa += PGSIZE)
    {
        pte_t *ptep = get_pte(pgdir, la, 1);
        assert(ptep != NULL);
        *ptep = pte_create(pa >> PGSHIFT, PTE_V | perm);
    }
}

// boot_alloc_page - 使用 pmm->alloc_pages(1) 分配一个页
// 返回值: 分配的页的内核虚拟地址
// 注意: 此函数用于获取 PDT(Page Directory Table) 和 PT(Page Table) 的内存
static void *boot_alloc_page(void)
{
    struct Page *p = alloc_page();
    if (p == NULL)
    {
        panic("boot_alloc_page failed.\n");
    }
    return page2kva(p);
}
// pmm_init - 设置一个 pmm 来管理物理内存，构建 PDT&PT 以设置分页机制
//         - 检查 pmm 和分页机制的正确性，打印 PDT&PT
void pmm_init(void)
{
    // 我们需要分配/释放物理内存（粒度为 4KB 或其他大小）。
    // 因此在 pmm.h 中定义了一个物理内存管理器（struct pmm_manager）的框架。
    // 首先我们应该基于这个框架初始化一个物理内存管理器（pmm）。
    // 然后 pmm 可以分配/释放物理内存。
    // 现在有 first_fit/best_fit/worst_fit/buddy_system pmm 可用。
    init_pmm_manager();

    // 检测物理内存空间，保留已使用的内存，
    // 然后使用 pmm->init_memmap 创建空闲页列表
    page_init();

    // 使用 pmm->check 验证 pmm 中分配/释放函数的正确性
    check_alloc_page();
    // 创建 boot_pgdir，一个初始页目录（Page Directory Table，PDT）
    extern char boot_page_table_sv39[];
    boot_pgdir = (pte_t *)boot_page_table_sv39;
    boot_cr3 = PADDR(boot_pgdir);
    check_pgdir();
    static_assert(KERNBASE % PTSIZE == 0 && KERNTOP % PTSIZE == 0);

    // 将所有物理内存映射到以 KERNBASE 为基地址的线性内存
    // 线性地址 KERNBASE~KERNBASE+KMEMSIZE = 物理地址 0~KMEMSIZE
    // 但在 enable_paging() 和 gdt_init() 完成之前不应使用此映射。
    // boot_map_segment(boot_pgdir, KERNBASE, KMEMSIZE, PADDR(KERNBASE),
    //                READ_WRITE_EXEC);

    // 临时映射：
    // 虚拟地址 3G~3G+4M = 线性地址 0~4M = 线性地址 3G~3G+4M =
    // 物理地址 0~4M
    // boot_pgdir[0] = boot_pgdir[PDX(KERNBASE)];

    //    enable_paging();

    // 现在基本的虚拟内存映射（见 memlayout.h）已经建立。
    // 检查基本虚拟内存映射的正确性。
    check_boot_pgdir();
}

// get_pte - 获取 pte 并返回此 pte 对应的内核虚拟地址
//        - 如果 PT 包含的 pte 不存在，则为 PT 分配一个页
// 参数：
//  pgdir:  PDT 的内核虚拟基地址
//  la:     需要映射的线性地址
//  create: 一个逻辑值，决定是否为 PT 分配一个页
// 返回值：此 pte 的内核虚拟地址
pte_t *get_pte(pde_t *pgdir, uintptr_t la, bool create)
{
    /*
     *
     * 如果你需要访问物理地址，请使用 KADDR()
     * 请阅读 pmm.h 以获取有用的宏
     *
     * 也许你需要帮助注释，下面的注释可以帮助你完成代码
     *
     * 一些有用的宏和定义，你可以在下面的实现中使用它们。
     * 宏或函数：
     *   PDX(la) = 虚拟地址 la 的页目录项索引。
     *   KADDR(pa) : 获取物理地址并返回相应的内核虚拟地址。
     *   set_page_ref(page,1) : 表示该页被引用了一次
     *   page2pa(page): 获取此（struct Page *）page 管理的内存的物理地址
     *   struct Page * alloc_page() : 分配一个页
     *   memset(void *s, char c, size_t n) : 将指向 s 的内存区域的前 n 个字节设置为指定值 c。
     * 定义：
     *   PTE_P           0x001                   // 页表/目录项标志位：存在
     *   PTE_W           0x002                   // 页表/目录项标志位：可写
     *   PTE_U           0x004                   // 页表/目录项标志位：用户可访问
     */
    pde_t *pdep1 = &pgdir[PDX1(la)];
    if (!(*pdep1 & PTE_V))
    {
        struct Page *page;
        if (!create || (page = alloc_page()) == NULL)
        {
            return NULL;
        }
        set_page_ref(page, 1);
        uintptr_t pa = page2pa(page);
        memset(KADDR(pa), 0, PGSIZE);
        *pdep1 = pte_create(page2ppn(page), PTE_U | PTE_V);
    }
    pde_t *pdep0 = &((pde_t *)KADDR(PDE_ADDR(*pdep1)))[PDX0(la)];
    //    pde_t *pdep0 = &((pde_t *)(PDE_ADDR(*pdep1)))[PDX0(la)];
    if (!(*pdep0 & PTE_V))
    {
        struct Page *page;
        if (!create || (page = alloc_page()) == NULL)
        {
            return NULL;
        }
        set_page_ref(page, 1);
        uintptr_t pa = page2pa(page);
        memset(KADDR(pa), 0, PGSIZE);
        //   	memset(pa, 0, PGSIZE);
        *pdep0 = pte_create(page2ppn(page), PTE_U | PTE_V);
    }
    return &((pte_t *)KADDR(PDE_ADDR(*pdep0)))[PTX(la)];
}

// get_page - 使用 PDT pgdir 获取线性地址 la 相关的 Page 结构
struct Page *get_page(pde_t *pgdir, uintptr_t la, pte_t **ptep_store)
{
    pte_t *ptep = get_pte(pgdir, la, 0);
    if (ptep_store != NULL)
    {
        *ptep_store = ptep;
    }
    if (ptep != NULL && *ptep & PTE_V)
    {
        return pte2page(*ptep);
    }
    return NULL;
}
// page_remove_pte - 释放与线性地址 la 相关的 Page 结构
//                - 并清除（无效）与线性地址 la 相关的 pte
// 注意：PT 已更改，因此需要使 TLB 无效
static inline void page_remove_pte(pde_t *pgdir, uintptr_t la, pte_t *ptep)
{
    /*
     *
     * 请检查 ptep 是否有效，如果映射更新，则必须手动更新 tlb
     *
     * 也许你需要帮助注释，下面的注释可以帮助你完成代码
     *
     * 一些有用的宏和定义，你可以在下面的实现中使用它们。
     * 宏或函数：
     *   struct Page *page pte2page(*ptep): 从 ptep 的值获取相应的页
     *   free_page : 释放一个页
     *   page_ref_dec(page) : 减少 page->ref。注意：如果 page->ref == 0 ，
     * 则应释放此页。
     *   tlb_invalidate(pde_t *pgdir, uintptr_t la) : 使 TLB 条目无效，
     * 但前提是正在编辑的页表是处理器当前使用的页表。
     * 定义：
     *   PTE_P           0x001                   // 页表/目录项标志位：存在
     */
    if (*ptep & PTE_V)
    { //(1) 检查此页表项是否有效
        struct Page *page =
            pte2page(*ptep); //(2) 找到与 pte 对应的页
        page_ref_dec(page);  //(3) 减少页引用
        if (page_ref(page) ==
            0)
        { //(4) 当页引用达到 0 时释放此页
            free_page(page);
        }
        *ptep = 0;                 //(5) 清除二级页表项
        tlb_invalidate(pgdir, la); //(6) 刷新 tlb
    }
}

// page_remove - 释放与线性地址 la 相关并具有有效 pte 的 Page
void page_remove(pde_t *pgdir, uintptr_t la)
{
    pte_t *ptep = get_pte(pgdir, la, 0);
    if (ptep != NULL)
    {
        page_remove_pte(pgdir, la, ptep);
    }
}

// page_insert - 构建具有线性地址 la 的 Page 的物理地址映射
// 参数：
//  pgdir: PDT 的内核虚拟基地址
//  page:  需要映射的 Page
//  la:    需要映射的线性地址
//  perm:  设置在相关 pte 中的 Page 权限
// 返回值：始终为 0
// 注意：PT 已更改，因此需要使 TLB 无效
int page_insert(pde_t *pgdir, struct Page *page, uintptr_t la, uint32_t perm)
{
    pte_t *ptep = get_pte(pgdir, la, 1);
    if (ptep == NULL)
    {
        return -E_NO_MEM;
    }
    page_ref_inc(page);
    if (*ptep & PTE_V)
    {
        struct Page *p = pte2page(*ptep);
        if (p == page)
        {
            page_ref_dec(page);
        }
        else
        {
            page_remove_pte(pgdir, la, ptep);
        }
    }
    *ptep = pte_create(page2ppn(page), PTE_V | perm);
    tlb_invalidate(pgdir, la);
    return 0;
}

// 使 TLB 条目无效，但前提是正在编辑的页表是处理器当前使用的页表。
void tlb_invalidate(pde_t *pgdir, uintptr_t la) { flush_tlb(); }

// pgdir_alloc_page - 调用 alloc_page 和 page_insert 函数
//                  - 分配一个页大小的内存并设置地址映射
//                  - pa<->la 具有线性地址 la 和 PDT pgdir
struct Page *pgdir_alloc_page(pde_t *pgdir, uintptr_t la, uint32_t perm)
{
    struct Page *page = alloc_page();
    if (page != NULL)
    {
        if (page_insert(pgdir, page, la, perm) != 0)
        {
            free_page(page);
            return NULL;
        }
        if (swap_init_ok)
        {
            swap_map_swappable(check_mm_struct, la, page, 0);
            page->pra_vaddr = la;
            assert(page_ref(page) == 1);
            // cprintf("get No. %d  page: pra_vaddr %x, pra_link.prev %x,
            // pra_link_next %x in pgdir_alloc_page\n", (page-pages),
            // page->pra_vaddr,page->pra_page_link.prev,
            // page->pra_page_link.next);
        }
    }

    return page;
}

static void check_alloc_page(void)
{
    pmm_manager->check();
    cprintf("check_alloc_page() succeeded!\n");
}

static void check_pgdir(void)
{
    // assert(npage <= KMEMSIZE / PGSIZE);
    // 内存从 RISC-V 中的 2GB 开始
    // 因此 npage 始终大于 KMEMSIZE / PGSIZE
    size_t nr_free_store;

    nr_free_store = nr_free_pages();

    assert(npage <= KERNTOP / PGSIZE);
    assert(boot_pgdir != NULL && (uint32_t)PGOFF(boot_pgdir) == 0);
    assert(get_page(boot_pgdir, 0x0, NULL) == NULL);

    struct Page *p1, *p2;
    p1 = alloc_page();
    assert(page_insert(boot_pgdir, p1, 0x0, 0) == 0);
    pte_t *ptep;
    assert((ptep = get_pte(boot_pgdir, 0x0, 0)) != NULL);
    assert(pte2page(*ptep) == p1);
    assert(page_ref(p1) == 1);

    ptep = (pte_t *)KADDR(PDE_ADDR(boot_pgdir[0]));
    ptep = (pte_t *)KADDR(PDE_ADDR(ptep[0])) + 1;
    assert(get_pte(boot_pgdir, PGSIZE, 0) == ptep);

    p2 = alloc_page();
    assert(page_insert(boot_pgdir, p2, PGSIZE, PTE_U | PTE_W) == 0);
    assert((ptep = get_pte(boot_pgdir, PGSIZE, 0)) != NULL);
    assert(*ptep & PTE_U);
    assert(*ptep & PTE_W);
    assert(boot_pgdir[0] & PTE_U);
    assert(page_ref(p2) == 1);

    assert(page_insert(boot_pgdir, p1, PGSIZE, 0) == 0);
    assert(page_ref(p1) == 2);
    assert(page_ref(p2) == 0);
    assert((ptep = get_pte(boot_pgdir, PGSIZE, 0)) != NULL);
    assert(pte2page(*ptep) == p1);
    assert((*ptep & PTE_U) == 0);

    page_remove(boot_pgdir, 0x0);
    assert(page_ref(p1) == 1);
    assert(page_ref(p2) == 0);

    page_remove(boot_pgdir, PGSIZE);
    assert(page_ref(p1) == 0);
    assert(page_ref(p2) == 0);

    assert(page_ref(pde2page(boot_pgdir[0])) == 1);

    pde_t *pd1 = boot_pgdir, *pd0 = page2kva(pde2page(boot_pgdir[0]));
    free_page(pde2page(pd0[0]));
    free_page(pde2page(pd1[0]));
    boot_pgdir[0] = 0;

    assert(nr_free_store == nr_free_pages());

    cprintf("check_pgdir() succeeded!\n");
}

static void check_boot_pgdir(void)
{
    size_t nr_free_store;
    pte_t *ptep;
    int i;

    nr_free_store = nr_free_pages();

    for (i = ROUNDDOWN(KERNBASE, PGSIZE); i < npage * PGSIZE; i += PGSIZE)
    {
        assert((ptep = get_pte(boot_pgdir, (uintptr_t)KADDR(i), 0)) != NULL);
        assert(PTE_ADDR(*ptep) == i);
    }

    assert(boot_pgdir[0] == 0);

    struct Page *p;
    p = alloc_page();
    assert(page_insert(boot_pgdir, p, 0x100, PTE_W | PTE_R) == 0);
    assert(page_ref(p) == 1);
    assert(page_insert(boot_pgdir, p, 0x100 + PGSIZE, PTE_W | PTE_R) == 0);
    assert(page_ref(p) == 2);

    const char *str = "ucore: Hello world!!";
    strcpy((void *)0x100, str);
    assert(strcmp((void *)0x100, (void *)(0x100 + PGSIZE)) == 0);

    *(char *)(page2kva(p) + 0x100) = '\0';
    assert(strlen((const char *)0x100) == 0);

    pde_t *pd1 = boot_pgdir, *pd0 = page2kva(pde2page(boot_pgdir[0]));
    free_page(p);
    free_page(pde2page(pd0[0]));
    free_page(pde2page(pd1[0]));
    boot_pgdir[0] = 0;

    assert(nr_free_store == nr_free_pages());

    cprintf("check_boot_pgdir() succeeded!\n");
}

void *kmalloc(size_t n)
{
    void *ptr = NULL;
    struct Page *base = NULL;
    assert(n > 0 && n < 1024 * 0124);
    int num_pages = (n + PGSIZE - 1) / PGSIZE;
    base = alloc_pages(num_pages);
    assert(base != NULL);
    ptr = page2kva(base);
    return ptr;
}

void kfree(void *ptr, size_t n)
{
    assert(n > 0 && n < 1024 * 0124);
    assert(ptr != NULL);
    struct Page *base = NULL;
    int num_pages = (n + PGSIZE - 1) / PGSIZE;
    base = kva2page(ptr);
    free_pages(base, num_pages);
}
