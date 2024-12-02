#include <proc.h>
#include <kmalloc.h>
#include <string.h>
#include <sync.h>
#include <pmm.h>
#include <error.h>
#include <sched.h>
#include <elf.h>
#include <vmm.h>
#include <trap.h>
#include <stdio.h>
#include <stdlib.h>
#include <assert.h>

/* ------------- 进程/线程机制设计与实现 -------------
(一个简化的Linux进程/线程机制)
简介:
    ucore实现了一个简单的进程/线程机制。进程包含独立的内存空间，至少一个用于执行的线程，内核数据（用于管理），处理器状态（用于上下文切换）
    ，文件（在lab6中），等等。ucore需要高效地管理所有这些细节。在ucore中，线程只是进程的一种特殊形式（共享进程的内存）。
------------------------------
进程状态        :     含义               -- 原因
PROC_UNINIT    :   未初始化             -- alloc_proc
PROC_SLEEPING  :   睡眠                 -- try_free_pages, do_wait, do_sleep
PROC_RUNNABLE  :   可运行（可能正在运行） -- proc_init, wakeup_proc,
PROC_ZOMBIE    :   几乎死亡             -- do_exit

-----------------------------
process state changing:

  alloc_proc                                 RUNNING
      +                                   +--<----<--+
      +                                   + proc_run +
      V                                   +-->---->--+
PROC_UNINIT -- proc_init/wakeup_proc --> PROC_RUNNABLE -- try_free_pages/do_wait/do_sleep --> PROC_SLEEPING --
                                           A      +                                                           +
                                           |      +--- do_exit --> PROC_ZOMBIE                                +
                                           +                                                                  +
                                           -----------------------wakeup_proc----------------------------------
-----------------------------
进程关系
父进程:           proc->parent  (proc是子进程)
子进程:           proc->cptr    (proc是父进程)
兄弟进程:         proc->optr    (proc是弟弟进程)
弟弟进程:         proc->yptr    (proc是兄弟进程)
-----------------------------
与进程相关的系统调用:
SYS_exit        : 进程退出,                           -->do_exit
SYS_fork        : 创建子进程, 复制mm                  -->do_fork-->wakeup_proc
SYS_wait        : 等待进程                            -->do_wait
SYS_exec        : fork后，进程执行一个程序             -->加载一个程序并刷新mm
SYS_clone       : 创建子线程                          -->do_fork-->wakeup_proc
SYS_yield       : 进程标记自己需要重新调度,           -- proc->need_sched=1, 然后调度器将重新调度此进程
SYS_sleep       : 进程睡眠                            -->do_sleep
SYS_kill        : 杀死进程                            -->do_kill-->proc->flags |= PF_EXITING
                                                                                                                                 -->wakeup_proc-->do_wait-->do_exit
SYS_getpid      : 获取进程的pid

*/

// 进程集合的列表
list_entry_t proc_list;

#define HASH_SHIFT 10
#define HASH_LIST_SIZE (1 << HASH_SHIFT)
#define pid_hashfn(x) (hash32(x, HASH_SHIFT))

// 基于pid的进程集合的哈希列表
static list_entry_t hash_list[HASH_LIST_SIZE];

// 空闲进程
struct proc_struct *idleproc = NULL;
// 初始化进程
struct proc_struct *initproc = NULL;
// 当前进程
struct proc_struct *current = NULL;

static int nr_process = 0;

void kernel_thread_entry(void);
void forkrets(struct trapframe *tf);
void switch_to(struct context *from, struct context *to);

// alloc_proc - 分配一个proc_struct并初始化proc_struct的所有字段
static struct proc_struct *
alloc_proc(void)
{
    struct proc_struct *proc = kmalloc(sizeof(struct proc_struct));
    if (proc != NULL)
    {
        // LAB4:EXERCISE1 2211771
        /*
         * 需要初始化proc_struct中的以下字段
         *       enum proc_state state;                      // 进程状态
         *       int pid;                                    // 进程ID
         *       int runs;                                   // 进程的运行次数
         *       uintptr_t kstack;                           // 进程内核栈
         *       volatile bool need_resched;                 // 布尔值：是否需要重新调度以释放CPU？
         *       struct proc_struct *parent;                 // 父进程
         *       struct mm_struct *mm;                       // 进程的内存管理字段
         *       struct context context;                     // 切换到此处运行进程
         *       struct trapframe *tf;                       // 当前中断的陷阱帧
         *       uintptr_t cr3;                              // CR3寄存器：页目录表（PDT）的基地址
         *       uint32_t flags;                             // 进程标志
         *       char name[PROC_NAME_LEN + 1];               // 进程名称
         */
        proc->cr3 = boot_cr3;
        proc->tf = NULL;
        memset(&(proc->context), 0, sizeof(struct context));
        proc->state = PROC_UNINIT;
        proc->pid = -1;
        proc->runs = 0;
        proc->kstack = 0;
        proc->need_resched = 0;
        proc->parent = NULL;
        proc->mm = NULL;
        proc->flags = 0;
        memset(proc->name, 0, sizeof(proc->name));
    }
    return proc;
}

// set_proc_name - 设置进程的名称
char *
set_proc_name(struct proc_struct *proc, const char *name)
{
    memset(proc->name, 0, sizeof(proc->name));
    return memcpy(proc->name, name, PROC_NAME_LEN);
}

// get_proc_name - 获取进程的名称
char *
get_proc_name(struct proc_struct *proc)
{
    static char name[PROC_NAME_LEN + 1];
    memset(name, 0, sizeof(name));
    return memcpy(name, proc->name, PROC_NAME_LEN);
}

// get_pid - 为进程分配一个唯一的pid
static int
get_pid(void)
{
    static_assert(MAX_PID > MAX_PROCESS);
    struct proc_struct *proc;
    list_entry_t *list = &proc_list, *le;
    static int next_safe = MAX_PID, last_pid = MAX_PID;
    if (++last_pid >= MAX_PID)
    {
        last_pid = 1;
        goto inside;
    }
    if (last_pid >= next_safe)
    {
    inside:
        next_safe = MAX_PID;
    repeat:
        le = list;
        while ((le = list_next(le)) != list)
        {
            proc = le2proc(le, list_link);
            if (proc->pid == last_pid)
            {
                if (++last_pid >= next_safe)
                {
                    if (last_pid >= MAX_PID)
                    {
                        last_pid = 1;
                    }
                    next_safe = MAX_PID;
                    goto repeat;
                }
            }
            else if (proc->pid > last_pid && next_safe > proc->pid)
            {
                next_safe = proc->pid;
            }
        }
    }
    return last_pid;
}

// proc_run - 使进程"proc"在CPU上运行
// 注意：在调用switch_to之前，应加载"proc"的新PDT的基地址
void proc_run(struct proc_struct *proc)
{
    if (proc != current)
    {
        // LAB4:EXERCISE3 2211771
        /*
         * 一些有用的宏、函数和定义，你可以在下面的实现中使用它们。
         * 宏或函数：
         *   local_intr_save():        禁用中断
         *   local_intr_restore():     启用中断
         *   lcr3():                   修改CR3寄存器的值
         *   switch_to():              在两个进程之间进行上下文切换
         */
        // 检查当前运行的进程是否和即将运行的进程相同
        if (current == proc)
            return;
        struct proc_struct *prev = current, *next = proc;
        // 禁用中断
        bool flag;
        local_intr_save(flag);
        {
            // 切换进程
            current = proc;
            // 切换页表
            lcr3(proc->cr3);
            // 上下文切换
            switch_to(&(prev->context), &(next->context));
        }
        // 允许中断
        local_intr_restore(flag);
    }
}

// forkret -- 新线程/进程的第一个内核入口点
// 注意：forkret的地址在copy_thread函数中设置
//       在switch_to之后，当前进程将在此处执行。
static void
forkret(void)
{
    forkrets(current->tf);
}

// hash_proc - 将进程添加到进程哈希列表中
static void
hash_proc(struct proc_struct *proc)
{
    list_add(hash_list + pid_hashfn(proc->pid), &(proc->hash_link));
}

// find_proc - 根据pid从进程哈希列表中查找进程
struct proc_struct *
find_proc(int pid)
{
    if (0 < pid && pid < MAX_PID)
    {
        list_entry_t *list = hash_list + pid_hashfn(pid), *le = list;
        while ((le = list_next(le)) != list)
        {
            struct proc_struct *proc = le2proc(le, hash_link);
            if (proc->pid == pid)
            {
                return proc;
            }
        }
    }
    return NULL;
}

// kernel_thread - 使用"fn"函数创建一个内核线程
// 注意：临时陷阱帧tf的内容将在do_fork-->copy_thread函数中复制到proc->tf
int kernel_thread(int (*fn)(void *), void *arg, uint32_t clone_flags)
{
    struct trapframe tf;
    memset(&tf, 0, sizeof(struct trapframe));
    tf.gpr.s0 = (uintptr_t)fn;
    tf.gpr.s1 = (uintptr_t)arg;
    tf.status = (read_csr(sstatus) | SSTATUS_SPP | SSTATUS_SPIE) & ~SSTATUS_SIE;
    tf.epc = (uintptr_t)kernel_thread_entry;
    return do_fork(clone_flags | CLONE_VM, 0, &tf);
}

// setup_kstack - 分配大小为KSTACKPAGE的页面作为进程内核栈
static int
setup_kstack(struct proc_struct *proc)
{
    struct Page *page = alloc_pages(KSTACKPAGE);
    if (page != NULL)
    {
        proc->kstack = (uintptr_t)page2kva(page);
        return 0;
    }
    return -E_NO_MEM;
}

// put_kstack - 释放进程内核栈的内存空间
static void
put_kstack(struct proc_struct *proc)
{
    free_pages(kva2page((void *)(proc->kstack)), KSTACKPAGE);
}

// copy_mm - 进程"proc"根据clone_flags复制或共享进程"current"的mm
//         - 如果clone_flags & CLONE_VM，则"共享"；否则"复制"
static int
copy_mm(uint32_t clone_flags, struct proc_struct *proc)
{
    assert(current->mm == NULL);
    /* 在这个项目中不做任何事情 */
    return 0;
}

// copy_thread - 在进程的内核栈顶设置陷阱帧
//             - 设置进程的内核入口点和栈
static void
copy_thread(struct proc_struct *proc, uintptr_t esp, struct trapframe *tf)
{
    proc->tf = (struct trapframe *)(proc->kstack + KSTACKSIZE - sizeof(struct trapframe));
    *(proc->tf) = *tf;

    // 将a0设置为0，以便子进程知道它刚刚被fork
    proc->tf->gpr.a0 = 0;
    proc->tf->gpr.sp = (esp == 0) ? (uintptr_t)proc->tf : esp;

    proc->context.ra = (uintptr_t)forkret;
    proc->context.sp = (uintptr_t)(proc->tf);
}

/* do_fork -     为新子进程的父进程
 * @clone_flags: 用于指导如何克隆子进程
 * @stack:       父进程的用户栈指针。如果stack==0，表示fork一个内核线程。
 * @tf:          陷阱帧信息，将被复制到子进程的proc->tf
 */
int do_fork(uint32_t clone_flags, uintptr_t stack, struct trapframe *tf)
{
    int ret = -E_NO_FREE_PROC;
    struct proc_struct *proc;
    if (nr_process >= MAX_PROCESS)
    {
        goto fork_out;
    }
    ret = -E_NO_MEM;
    // LAB4:EXERCISE2 2211771
    /*
     * 一些有用的宏、函数和定义，你可以在下面的实现中使用它们。
     * 宏或函数：
     *   alloc_proc:   创建一个proc结构并初始化字段（lab4:exercise1）
     *   setup_kstack: 分配大小为KSTACKPAGE的页面作为进程内核栈
     *   copy_mm:      根据clone_flags复制或共享进程"current"的mm
     *                 如果clone_flags & CLONE_VM，则"共享"；否则"复制"
     *   copy_thread:  在进程的内核栈顶设置陷阱帧
     *                 设置进程的内核入口点和栈
     *   hash_proc:    将进程添加到进程哈希列表中
     *   get_pid:      为进程分配一个唯一的pid
     *   wakeup_proc:  设置proc->state = PROC_RUNNABLE
     * 变量：
     *   proc_list:    进程集合的列表
     *   nr_process:   进程集合的数量
     */
    //    1. 调用alloc_proc分配一个proc_struct
    //    2. 调用setup_kstack为子进程分配一个内核栈
    //    3. 调用copy_mm根据clone_flag复制或共享mm
    //    4. 调用copy_thread在proc_struct中设置tf和上下文
    //    5. 将proc_struct插入hash_list和proc_list
    //    6. 调用wakeup_proc使新子进程RUNNABLE
    //    7. 使用子进程的pid设置ret值
    if ((proc = alloc_proc()) == NULL)
    {
        goto bad_fork_cleanup_proc;
    }
    proc->parent = current;
    setup_kstack(proc);
    copy_mm(clone_flags, proc);
    copy_thread(proc, stack, tf);
    int p = get_pid();
    proc->pid = p;
    hash_proc(proc);
    list_add(&proc_list, &(proc->list_link));
    nr_process++;
    wakeup_proc(proc);
    ret = proc->pid;

fork_out:
    cprintf("do_fork out\n");
    return ret;

bad_fork_cleanup_kstack:
    put_kstack(proc);
bad_fork_cleanup_proc:
    kfree(proc);
    goto fork_out;
}

// do_exit - 由sys_exit调用
//   1. 调用exit_mmap和put_pgdir和mm_destroy释放几乎所有的进程内存空间
//   2. 将进程状态设置为PROC_ZOMBIE，然后调用wakeup_proc(parent)请求父进程回收自己。
//   3. 调用调度器切换到其他进程
int do_exit(int error_code)
{
    panic("进程退出!!.\n");
}

// init_main - 第二个内核线程，用于创建user_main内核线程
static int
init_main(void *arg)
{
    cprintf("这是initproc, pid = %d, 名称 = \"%s\"\n", current->pid, get_proc_name(current));
    cprintf("To U: \"%s\".\n", (const char *)arg);
    cprintf("To U: \"嗯.., 再见, 再见. :)\"\n");
    return 0;
}

// proc_init - 通过自身设置第一个内核线程idleproc "idle"
//           - 创建第二个内核线程init_main
void proc_init(void)
{
    int i;

    list_init(&proc_list);
    for (i = 0; i < HASH_LIST_SIZE; i++)
    {
        list_init(hash_list + i);
    }

    if ((idleproc = alloc_proc()) == NULL)
    {
        panic("无法分配idleproc。\n");
    }
    // 检查proc结构
    int *context_mem = (int *)kmalloc(sizeof(struct context));
    memset(context_mem, 0, sizeof(struct context));
    int context_init_flag = memcmp(&(idleproc->context), context_mem, sizeof(struct context));

    int *proc_name_mem = (int *)kmalloc(PROC_NAME_LEN);
    memset(proc_name_mem, 0, PROC_NAME_LEN);
    int proc_name_flag = memcmp(&(idleproc->name), proc_name_mem, PROC_NAME_LEN);

    if (idleproc->cr3 == boot_cr3 &&
        idleproc->tf == NULL &&
        !context_init_flag &&
        idleproc->state == PROC_UNINIT &&
        idleproc->pid == -1 &&
        idleproc->runs == 0 &&
        idleproc->kstack == 0 &&
        idleproc->need_resched == 0 &&
        idleproc->parent == NULL &&
        idleproc->mm == NULL &&
        idleproc->flags == 0 &&
        !proc_name_flag)
    {
        cprintf("alloc_proc() 正确!\n");
    }

    idleproc->pid = 0;
    idleproc->state = PROC_RUNNABLE;
    idleproc->kstack = (uintptr_t)bootstack;
    idleproc->need_resched = 1;
    set_proc_name(idleproc, "idle");
    nr_process++;

    current = idleproc;

    int pid = kernel_thread(init_main, "Hello world!!", 0);
    if (pid <= 0)
    {
        panic("创建init_main失败。\n");
    }

    initproc = find_proc(pid);
    set_proc_name(initproc, "init");

    assert(idleproc != NULL && idleproc->pid == 0);
    assert(initproc != NULL && initproc->pid == 1);
}

// cpu_idle - 在kern_init结束时，第一个内核线程idleproc将执行以下工作
void cpu_idle(void)
{
    while (1)
    {
        if (current->need_resched)
        {
            schedule();
        }
    }
}
