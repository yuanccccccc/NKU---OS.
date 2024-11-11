#include <defs.h>
#include <riscv.h>
#include <stdio.h>
#include <string.h>
#include <swap.h>
#include <swap_clock.h>
#include <list.h>
/**
 * CLOCK页面置换算法:
 *
 * CLOCK页面置换算法是最少最近使用（LRU）算法的简化版本。它使用一个循环列表（或“时钟”）来跟踪内存中的页面。
 * 每个页面都有一个引用位，指示它是否最近被访问过。
 *
 * 算法步骤:
 * 1. 当访问一个页面时，其引用位被设置为1。
 * 2. 当需要替换页面时，算法以循环方式检查引用位（类似于时钟的指针）。
 * 3. 如果页面的引用位为0，则用新页面替换它。
 * 4. 如果页面的引用位为1，则清除该位（设置为0），并且算法移动到循环列表中的下一个页面。
 * 5. 这个过程持续进行，直到找到引用位为0的页面。
 *
 * CLOCK算法在时间复杂度方面是高效的，并且以较低的开销提供了LRU算法的良好近似。
 */
list_entry_t pra_list_head, *curr_ptr;
/*
 * (2) _fifo_init_mm: 初始化pra_list_head并让mm->sm_priv指向pra_list_head的地址。
 *              现在，从内存控制结构体mm_struct中，我们可以访问FIFO PRA。
 */
static int
_clock_init_mm(struct mm_struct *mm)
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
_clock_map_swappable(struct mm_struct *mm, uintptr_t addr, struct Page *page, int swap_in)
{
    list_entry_t *entry = &(page->pra_page_link);

    assert(entry != NULL && curr_ptr != NULL);
    // record the page access situlation
    /*LAB3 EXERCISE 4: 2211771*/
    // 将页面page插入到页面链表pra_list_head的末尾
    list_add(curr_ptr, entry);
    // 将页面的visited标志置为1，表示该页面已被访问
    page->visited = 1;
    return 0;
}
/*
 *  (4)_fifo_swap_out_victim: According FIFO PRA, we should unlink the  earliest arrival page in front of pra_list_head qeueue,
 *                            then set the addr of addr of this page to ptr_page.
 */
static int
_clock_swap_out_victim(struct mm_struct *mm, struct Page **ptr_page, int in_tick)
{
    list_entry_t *head = (list_entry_t *)mm->sm_priv;
    assert(head != NULL);
    assert(in_tick == 0);
    struct Page *page;
    /* Select the victim */
    //(1)  unlink the  earliest arrival page in front of pra_list_head qeueue
    //(2)  set the addr of addr of this page to ptr_page
    if (list_empty(head))
    {
        ptr_page = NULL;
        return 0;
    }
    while (1)
    {
        /*LAB3 EXERCISE 4: 2211771*/
        // 编写代码
        // 遍历页面链表pra_list_head，查找最早未被访问的页面
        // 获取当前页面对应的Page结构指针
        // 如果当前页面未被访问，则将该页面从页面链表中删除，并将该页面指针赋值给ptr_page作为换出页面
        // 如果当前页面已被访问，则将visited标志置为0，表示该页面已被重新访问
        if (head == curr_ptr)
        {
            curr_ptr = list_prev(curr_ptr);
        }
        page = le2page(curr_ptr, pra_page_link);
        if (page->visited == 0)
        {
            list_del(curr_ptr);
            cprintf("curr_ptr: %p\n", curr_ptr);
            curr_ptr = list_prev(curr_ptr);
            *ptr_page = page;
            break;
        }
        else
        {
            page->visited = 0;
            curr_ptr = list_prev(curr_ptr);
        }
    }
    return 0;
}
static int
_clock_check_swap(void)
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
    cprintf("into check clock swap\n");
    *(unsigned char *)0x3000 = 0x0c;
    assert(pgfault_num == 4);
    *(unsigned char *)0x1000 = 0x0a;
    assert(pgfault_num == 4);
    *(unsigned char *)0x4000 = 0x0d;
    assert(pgfault_num == 4);
    *(unsigned char *)0x2000 = 0x0b;
    assert(pgfault_num == 4);
    *(unsigned char *)0x5000 = 0x0e;
    assert(pgfault_num == 5);
    *(unsigned char *)0x2000 = 0x0b;
    assert(pgfault_num == 5);
    *(unsigned char *)0x1000 = 0x0a;
    assert(pgfault_num == 5);
    *(unsigned char *)0x2000 = 0x0b;
    assert(pgfault_num == 5);
    *(unsigned char *)0x3000 = 0x0c;
    assert(pgfault_num == 5);
    *(unsigned char *)0x4000 = 0x0d;
    assert(pgfault_num == 5);
    *(unsigned char *)0x5000 = 0x0e;
    assert(pgfault_num == 5);
    assert(*(unsigned char *)0x1000 == 0x0a);
    *(unsigned char *)0x1000 = 0x0a;
    assert(pgfault_num == 6);
    cprintf("end check clock swap\n");
#endif
    return 0;
}

static int
_clock_init(void)
{
    return 0;
}

static int
_clock_set_unswappable(struct mm_struct *mm, uintptr_t addr)
{
    return 0;
}

static int
_clock_tick_event(struct mm_struct *mm)
{
    return 0;
}

struct swap_manager swap_manager_clock =
    {
        .name = "clock swap manager",
        .init = &_clock_init,
        .init_mm = &_clock_init_mm,
        .tick_event = &_clock_tick_event,
        .map_swappable = &_clock_map_swappable,
        .set_unswappable = &_clock_set_unswappable,
        .swap_out_victim = &_clock_swap_out_victim,
        .check_swap = &_clock_check_swap,
};
