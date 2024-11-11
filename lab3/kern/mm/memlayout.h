#ifndef __KERN_MM_MEMLAYOUT_H__
#define __KERN_MM_MEMLAYOUT_H__

/* 这个文件包含了我们操作系统中内存管理的定义。 */

/* *
 * 虚拟内存映射:                                          权限
 *                                                        内核/用户
 *
 *     4G ------------------> +---------------------------------+
 *                            |                                 |
 *                            |         空内存 (*)              |
 *                            |                                 |
 *                            +---------------------------------+ 0xFB000000
 *                            |   当前页表 (内核, 读写)         | 读写/-- PTSIZE
 *     VPT -----------------> +---------------------------------+ 0xFAC00000
 *                            |        无效内存 (*)             | --/--
 *     KERNTOP -------------> +---------------------------------+ 0xF8000000
 *                            |                                 |
 *                            |    重新映射的物理内存           | 读写/-- KMEMSIZE
 *                            |                                 |
 *     KERNBASE ------------> +---------------------------------+ 0xC0000000
 *                            |                                 |
 *                            |                                 |
 *                            |                                 |
 *                            ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
 * (*) 注意: 内核确保“无效内存”*永远*不会被映射。
 *     “空内存”通常未映射，但用户程序可以根据需要映射页面。
 *
 * */

/* 所有物理内存映射到这个地址 */
#define KERNBASE 0xFFFFFFFFC0200000 // = 0x80200000(物理内存里内核的起始位置, KERN_BEGIN_PADDR) + 0xFFFFFFFF40000000(偏移量, PHYSICAL_MEMORY_OFFSET)
// 把原有内存映射到虚拟内存空间的最后一页
#define KMEMSIZE 0x7E00000 // 最大物理内存量
// 0x7E00000 = 0x8000000 - 0x200000
// QEMU 缺省的RAM为 0x80000000到0x88000000, 128MiB, 0x80000000到0x80200000被OpenSBI占用
#define KERNTOP (KERNBASE + KMEMSIZE) // 0x88000000对应的虚拟地址

#define PHYSICAL_MEMORY_END 0x88000000
#define PHYSICAL_MEMORY_OFFSET 0xFFFFFFFF40000000
#define KERNEL_BEGIN_PADDR 0x80200000
#define KERNEL_BEGIN_VADDR 0xFFFFFFFFC0200000

#define KSTACKPAGE 2                     // 内核栈中的页数
#define KSTACKSIZE (KSTACKPAGE * PGSIZE) // 内核栈的大小

#ifndef __ASSEMBLER__

#include <defs.h>
#include <atomic.h>
#include <list.h>

typedef uintptr_t pte_t;
typedef uintptr_t pde_t;
typedef pte_t swap_entry_t; // pte也可以是一个交换条目

/* *
 * struct Page - 页描述符结构。每个Page描述一个物理页。在kern/mm/pmm.h中，你可以找到许多将Page转换为其他数据类型的有用函数，例如物理地址。
 * */
struct Page
{
    int ref;      // 页框的引用计数器
    uint_t flags; // 描述页框状态的标志数组
    uint_t visited;
    unsigned int property;      // 空闲块的数量，用于首次适配内存管理器
    list_entry_t page_link;     // 空闲列表链接
    list_entry_t pra_page_link; // 用于页面替换算法
    uintptr_t pra_vaddr;        // 用于页面替换算法
};

/* 描述页框状态的标志 */
#define PG_reserved 0 // 如果这个位=1: 该页被保留给内核，不能在alloc/free_pages中使用; 否则，这个位=0
#define PG_property 1 // 如果这个位=1: 该页是一个空闲内存块的头页(包含一些连续地址页)，可以在alloc_pages中使用; 如果这个位=0: 如果该页是一个空闲内存块的头页，那么该页和内存块已被分配。否则，该页不是空闲内存块的头页。

#define SetPageReserved(page) set_bit(PG_reserved, &((page)->flags))
#define ClearPageReserved(page) clear_bit(PG_reserved, &((page)->flags))
#define PageReserved(page) test_bit(PG_reserved, &((page)->flags))
#define SetPageProperty(page) set_bit(PG_property, &((page)->flags))
#define ClearPageProperty(page) clear_bit(PG_property, &((page)->flags))
#define PageProperty(page) test_bit(PG_property, &((page)->flags))

// 将列表条目转换为页
#define le2page(le, member) \
    to_struct((le), struct Page, member)

/* free_area_t - 维护一个双向链表来记录空闲(未使用)页 */
typedef struct
{
    list_entry_t free_list; // 列表头
    unsigned int nr_free;   // 该空闲列表中的空闲页数
} free_area_t;

#endif /* !__ASSEMBLER__ */

#endif /* !__KERN_MM_MEMLAYOUT_H__ */
