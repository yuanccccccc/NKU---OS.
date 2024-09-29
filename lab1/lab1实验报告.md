## 操作系统实验lab1
### 练习1 理解内核启动中的程序入口操作
问题：阅读 kern/init/entry.S内容代码，结合操作系统内核启动流程，说明指令 la sp, bootstacktop 完成了什么操作，目的是什么？ tail kern_init 完成了什么操作，目的是什么？
#### la sp,bootstacktop的作用
功能：该指令将 bootstacktop 的地址加载到栈指针 sp 中。
目的：初始化栈指针，为后续的函数调用和局部变量分配提供栈空间。栈是程序运行时管理临时数据（如函数参数和返回地址）的重要结构。
#### tail kern_init的作用
功能：跳转到 kern_init 函数的入口，开始内核的初始化过程。
目的：在内核启动时，执行初始化函数以设置系统的基本状态，如内存管理、进程管理等，为操作系统的正常运行奠定基础。
tail的作用是跳转不进行返回，即将cpu的控制权完全交给kern_init。
### 练习2 完善中断处理 （需要编程）
**题目：** 请编程完善trap.c中的中断处理函数trap，在对时钟中断进行处理的部分填写kern/trap/trap.c函数中处理时钟中断的部分，使操作系统每遇到100次时钟中断后，调用print_ticks子程序，向屏幕上打印一行文字”100 ticks”，在打印完10行后调用sbi.h中的shut_down()函数关机。
**回答：**
trap.c：
```c
case IRQ_S_TIMER:
        // 处理定时器中断
        clock_set_next_event();
        tick++; // 增加时钟中断计数
        if (tick % 100 == 0)//每100次时钟终端就打印一次
        {
            print_ticks(); // 打印信息
            num++;         // 增加打印行计数

            // 检查是否打印了10行
            if (num >= 10)
            {
                sbi_shutdown(); // 调用关机函数
            }
        }
```
### 扩展练习 Challenge1：描述与理解中断流程
**题目：** 描述ucore中处理中断异常的流程（从异常的产生开始），其中mov a0，sp的目的是什么？SAVE_ALL中寄存器保存在栈中的位置是什么确定的？对于任何中断，__alltraps 中都需要保存所有寄存器吗？请说明理由。
#### ucore中处理中断异常的流程
cpu从当前命令跳转到stvec，然后根据中断的种类执行不同的中断处理程序。
在Direct模式下，stevc直接指向中断处理处理程序的入口点。
跳转到中断入口点**align(2)**。
调用SAVE_ALL宏来保存当前的寄存器。
跳转到中断处理函数**trap**进行异常处理，然后在**trap**中将中断处理异常处理的工作分发给**interrupt_handler()**，**exception_handle()**，再进行更细致的处理。
中断处理结束后，调用RESTORE_ALL宏来恢复中断前的寄存器。
最后从sret返回到中断发生前的地址。
#### mov a0，sp的作用
将sp的值保存在a0寄存器中，方便中断处理函数中使用。
#### SAVE_ALL中寄存器保存在栈中的位置是什么确定的
寄存器保存在栈中的地址是根据sp寄存器的偏移计算得来的，在保存其他寄存器之前会先调整sp的地址，为保存其他寄存器留出空间。然后从当前sp的地址，逐个的保存寄存器。
#### 对于任何中断，__alltraps 中都需要保存所有寄存器吗？
从两方面来考虑：
一方面：为了保证上下文的连续性，要确保中断前后cpu的状态一样，我们需要完全的保存所有的寄存器，并在中断处理结束后，恢复所有的寄存器。
而另一方面，如果有些寄存器在中断处理过程中不会修改其中的值，我们也可以不保存来降低代价。
### 扩增练习 Challenge2：理解上下文切换机制
**题目：** 在trapentry.S中汇编代码 csrw sscratch, sp；csrrw s0, sscratch, x0实现了什么操作，目的是什么？save all里面保存了stval scause这些csr，而在restore all里面却不还原它们？那这样store的意义何在呢？
#### csrw sscratch, sp；csrrw s0, sscratch, x0实现了什么操作，目的是什么？
##### crsw sscratch,sp
将sp的值保存在sscratch寄存器中，这个操作的目的是为了方便在中断结束后能根据sp的值来恢复其他寄存器的值。
##### csrrw s0, sscratch, x0
将sscratch的值放入s0，将sscratch置零。
这个功能意味着，当我们处理异常时发现该寄存器是空的，就表明我们在递归的处理异常。
#### save all里面保存了stval scause这些csr，而在restore all里面却不还原它们？那这样store的意义何在呢？
保存 stval 和 scause 的意义：
在 SAVE_ALL 宏中，stval 和 scause 寄存器的值被保存，这些寄存器通常用于异常处理：scause 用于指示异常的原因。
stval 用于指示异常的相关值（如地址等）。
在异常处理中我们需要使用两个寄存器，因此异常结束后不需要再恢复。
而保存他们可以为潜在的需求提供便利。
### 扩展练习 Challenge3：完善异常
**题目：** 编程完善在触发一条非法指令异常 mret和，在 kern/trap/trap.c的异常处理函数中捕获，并对其进行处理，简单输出异常类型和异常指令触发地址，即“Illegal instruction caught at 0x(地址)”，“ebreak caught at 0x（地址）”与“Exception type:Illegal instruction"，“Exception type: breakpoint”。
触发异常：
**init.c:**
```c
    asm("mret");// 测试非法指令异常
    asm("ebreak");// 测试断点异常
```
处理异常时打印异常类型和异常指令触发地址：
**trap.c:**
```c
    case CAUSE_ILLEGAL_INSTRUCTION:
        // 非法指令异常处理
        /* LAB1 CHALLENGE3   YOUR CODE :  */
        /*(1)输出指令异常类型（ Illegal instruction）
         *(2)输出异常指令地址
         *(3)更新 tf->epc寄存器
         */
        cprintf("Exception type: Illegal instruction\n");
        cprintf("Illegal instruction caught at 0x%08x\n", tf->epc);
        // 更新 tf->epc 寄存器为下一条指令的地址，防止陷入死循环
        tf->epc += 4; // 假设每条指令占4个字节
        break;
    case CAUSE_BREAKPOINT:
        // 断点异常处理
        /* LAB1 CHALLLENGE3   YOUR CODE :  */
        /*(1)输出指令异常类型（ breakpoint）
         *(2)输出异常指令地址
         *(3)更新 tf->epc寄存器
         */
        cprintf("Exception type: breakpoint\n");
        cprintf("ebreak caught at 0x%08x\n", tf->epc);
        // 更新 tf->epc 寄存器为下一条指令的地址
        tf->epc += 2; // 假设每条指令占4个字节
        break;
```