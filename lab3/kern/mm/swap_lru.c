#include <defs.h>
#include <riscv.h>
#include <stdio.h>
#include <string.h>
#include <swap.h>
#include <swap_lru.h>
#include <pmm.h>
#include <list.h>
/**
 * LRU (Least Recently Used) 页面置换算法是一种常用的页面置换算法。
 * 其基本思想是将最近最少使用的页面置换出去，以便为新的页面腾出空间。
 * 具体实现通常使用一个链表或哈希表来跟踪页面的使用情况。
 * 当需要置换页面时，选择链表或哈希表中最久未使用的页面进行置换。
 * 这种算法在实际应用中能够较好地平衡时间和空间的开销。
 */
list_entry_t pra_list_head, *curr_ptr;
static int
_lru_init_mm(struct mm_struct *mm)
{
    /*LAB3 EXERCISE 4: 2211771*/
    // 初始化pra_list_head为空链表
    list_init(&pra_list_head);
    // 初始化当前指针curr_ptr指向pra_list_head，表示当前页面替换位置为链表头
    curr_ptr = &pra_list_head;
    // 将mm的私有成员指针指向pra_list_head，用于后续的页面替换算法操作
    mm->sm_priv = &pra_list_head;
    // cprintf(" mm->sm_priv %x in fifo_init_mm\n",mm->sm_priv);
    return 0;
}
/*
 * (3)_fifo_map_swappable: According FIFO PRA, we should link the most recent arrival page at the back of pra_list_head qeueue
 */
static int
_lru_map_swappable(struct mm_struct *mm, uintptr_t addr, struct Page *page, int swap_in)
{
    list_entry_t *entry = &(page->pra_page_link);
    list_entry_t *head = &pra_list_head;
    assert(entry != NULL && head != NULL);
    // record the page access situlation
    /*LAB3 EXERCISE 4: 2211771*/
    // 将页面page插入到页面链表pra_list_head的末尾
    list_add(head, entry);
    // 将页面的visited标志置为1，表示该页面已被访问
    return 0;
}
/*
 *  (4)_fifo_swap_out_victim: According FIFO PRA, we should unlink the  earliest arrival page in front of pra_list_head qeueue,
 *                            then set the addr of addr of this page to ptr_page.
 */
static int
_lru_swap_out_victim(struct mm_struct *mm, struct Page **ptr_page, int in_tick)
{
    list_entry_t *head = (list_entry_t *)mm->sm_priv;
    assert(head != NULL);
    assert(in_tick == 0);
    /* 选择受害者 */
    // (1) 取消链接pra_list_head队列最前面的页面
    // (2) 将该页面的地址设置为ptr_page
    list_entry_t *entry = list_prev(head);
    if (entry != head)
    {
        list_del(entry);
        *ptr_page = le2page(entry, pra_page_link);
    }
    else
    {
        *ptr_page = NULL;
    }
    return 0;
}

static uintptr_t _lru_access(uintptr_t addr)
{
    // update
    list_entry_t *head = &pra_list_head;
    pte_t **ptep_store = NULL;
    struct Page *page = get_page(boot_pgdir, addr, ptep_store);
    if (page != NULL)
    {
        list_entry_t *entry = &(page->pra_page_link);
        list_del(entry);
        list_add(head, entry);
    }
    return addr;
}

static int
_lru_check_swap(void)
{
#ifdef ucore_test
    int score = 0, totalscore = 5;
    cprintf("%d\n", &score);
    ++score;
    cprintf("grading %d/%d points", score, totalscore);
    *(unsigned char *)0x3000 = 0x0c;
    assert(pgfault_num == 4);
    *(unsigned char *)0x1000 = 0x0a;
    assert(pgfault_num == 4);
    *(unsigned char *)0x4000 = 0x0d;
    assert(pgfault_num == 4);
    *(unsigned char *)0x2000 = 0x0b;
    ++score;
    cprintf("grading %d/%d points", score, totalscore);
    assert(pgfault_num == 4);
    *(unsigned char *)0x5000 = 0x0e;
    assert(pgfault_num == 5);
    *(unsigned char *)0x2000 = 0x0b;
    assert(pgfault_num == 5);
    ++score;
    cprintf("grading %d/%d points", score, totalscore);
    *(unsigned char *)0x1000 = 0x0a;
    assert(pgfault_num == 5);
    *(unsigned char *)0x2000 = 0x0b;
    assert(pgfault_num == 5);
    *(unsigned char *)0x3000 = 0x0c;
    assert(pgfault_num == 5);
    ++score;
    cprintf("grading %d/%d points", score, totalscore);
    *(unsigned char *)0x4000 = 0x0d;
    assert(pgfault_num == 5);
    *(unsigned char *)0x5000 = 0x0e;
    assert(pgfault_num == 5);
    assert(*(unsigned char *)0x1000 == 0x0a);
    *(unsigned char *)0x1000 = 0x0a;
    assert(pgfault_num == 6);
    ++score;
    cprintf("grading %d/%d points", score, totalscore);
#else
    cprintf("into check lru swap\n");
    *(unsigned char *)_lru_access(0x3000) = 0x0c;
    assert(pgfault_num == 4);
    *(unsigned char *)_lru_access(0x1000) = 0x0a;
    assert(pgfault_num == 4);
    *(unsigned char *)_lru_access(0x4000) = 0x0d;
    assert(pgfault_num == 4);
    *(unsigned char *)_lru_access(0x2000) = 0x0b;
    assert(pgfault_num == 4);
    *(unsigned char *)_lru_access(0x5000) = 0x0e;
    assert(pgfault_num == 5);
    *(unsigned char *)_lru_access(0x2000) = 0x0b;
    assert(pgfault_num == 5);
    *(unsigned char *)_lru_access(0x1000) = 0x0a;
    assert(pgfault_num == 5);
    *(unsigned char *)_lru_access(0x2000) = 0x0b;
    assert(pgfault_num == 5);
    *(unsigned char *)_lru_access(0x3000) = 0x0c;
    assert(pgfault_num == 6);
    *(unsigned char *)_lru_access(0x4000) = 0x0d;
    assert(pgfault_num == 7);
    *(unsigned char *)_lru_access(0x5000) = 0x0e;
    assert(pgfault_num == 8);
    assert(*(unsigned char *)_lru_access(0x1000) == 0x0a);
    *(unsigned char *)_lru_access(0x1000) = 0x0a;
    assert(pgfault_num == 9);
    cprintf("end check lru swap\n");
#endif
    return 0;
}

static int
_lru_init(void)
{
    return 0;
}

static int
_lru_set_unswappable(struct mm_struct *mm, uintptr_t addr)
{
    return 0;
}

static int
_lru_tick_event(struct mm_struct *mm)
{
    return 0;
}

struct swap_manager swap_manager_lru =
    {
        .name = "lru swap manager",
        .init = &_lru_init,
        .init_mm = &_lru_init_mm,
        .tick_event = &_lru_tick_event,
        .map_swappable = &_lru_map_swappable,
        .set_unswappable = &_lru_set_unswappable,
        .swap_out_victim = &_lru_swap_out_victim,
        .check_swap = &_lru_check_swap,
};
