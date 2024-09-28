## Lab 1

### 练习 1：理解内核启动中的程序入口操作

> 阅读 `kern/init/entry.S`内容代码，结合操作系统内核启动流程，说明指令 `la sp, bootstacktop` 完成了什么操作，目的是什么？`tail kern_init` 完成了什么操作，目的是什么？

 **`la sp, bootstacktop`** 

- `la`：`load address` 指令，用于将符号地址加载到寄存器中
- `sp`：栈指针寄存器
- `bootstacktop`：一个符号，表示内核启动栈的顶端地址

内核启动时需要为内核代码分配栈空间， `la sp, bootstacktop` 将 `bootstacktop` 的地址加载到 `sp` 寄存器。

对于

```assembly
.section .data
    # .align 2^12
    .align PGSHIFT
    .global bootstack
bootstack:
    .space KSTACKSIZE
    .global bootstacktop
bootstacktop:
```

`memlayout.h` 中定义了 `KSTACKPAGE` 为 2，每页大小为 `PGSIZE`（4096 字节），因此 `KSTACKSIZE` 为 8192 字节。使用 GDB 进行查看 `bootstacktop` 和 `bootstack` 符号地址，得到

```
(gdb) info address bootstacktop
Symbol "bootstacktop" is at 0x80204000 in a file compiled without debugging.
(gdb) info address bootstack
Symbol "bootstack" is at 0x80202000 in a file compiled without debugging.
```

可以看到  `bootstacktop` 和 `bootstack` 之间的栈空间为  `KSTACKSIZE` 8KB 即 8192 字节。

**`tail kern_init`**

- `tail`：一个伪指令，用于生成尾调用（tail call），将 PC 设置为 `kern_init` 函数的地址，并跳转过去但不保留返回地址。无需保存不必要的栈帧，提高执行效率。
- `kern_init`：`kern_init` 函数的标签，进一步初始化内核



### 练习 2：完善中断处理

> 简要说明实现过程和定时器中断处理的流程

**中断处理的流程**：

当发生 trap 时，CPU 通过中断处理程序来处理中断，中断程序位置由 stvec 指向。在 ucore 中，`idt_init` 函数初始化中断处理，将 `__alltraps` 设置为为中断处理函数。在 `__alltraps` 中，`SAVE_ALL`  宏保存所有相关的 CPU 寄存器和 CSR 到栈中，并调用 `trap` 函数来处理 trap。`trap` 函数接收 trap 帧指针并调用 `trap_dispatch` 来确定 trap 类型，对于中断类型的 trap，由 `interrupt_handler` 处理；对于异常类型的中断，由 `exception_handler` 处理。不同类型的 trap 有不同的操作。trap 处理完毕后，`RESTORE_ALL` 宏从堆栈中恢复先前保存的 CPU 状态，执行 `sret` 指令，恢复 `sepc` 和 `sstatus`，继续正常执行。

对于定时器时钟中断，首先需要使用 OpenSBI 提供的`sbi_set_timer()`接口触发时钟中断，设置合适的间隔，并在触发一次时钟中断时设置下一次时钟中断。在 trap 函数中，对于时钟中断，由 `interrupt_handler` 处理。实现 10 次 ticks 后关机，只需要加上计数逻辑，并适时调用包装过的接口 `sbi_shutdown()` 即可。



### 扩展练习 Challenge1：描述与理解中断流程

> 描述 ucore 中处理中断异常的流程（从异常的产生开始），其中 `mov a0，sp` 的目的是什么？`SAVE_ALL` 中寄寄存器保存在栈中的位置是什么确定的？对于任何中断，`__alltraps` 中都需要保存所有寄存器吗？请说明理由。

1.  **`mov a0，sp` 的目的是什么？**

   `mov a0, sp` 将当前的堆栈指针 (`sp`) 的值移动到寄存器 `a0` 中，寄存器 `a0` 用于传递函数的第一个参数，`sp` 指向的堆栈位置包含了 `SAVE_ALL` 宏保存的所有寄存器值和相关的控制与状态信息， `trap` 函数可以读取这些信息来进行对应的处理。

2. **`SAVE_ALL` 中寄寄存器保存在栈中的位置是什么确定的？**

   调用 `SAVE_ALL` 时，通过 `addi sp, sp, -36 * REGBYTES` 分配了足够的栈空间，每个寄存器在堆栈中的保存位置是通过其在 `SAVE_ALL` 宏中的保存顺序和预定义的偏移量确定的，如`x0` 保存到 `0*REGBYTES(sp)`，`s0`保存到 `2*REGBYTES(sp)`。

3. **对于任何中断，`__alltraps` 中都需要保存所有寄存器吗？**

   对于某些中断处理，可能只需要修改或使用特定的寄存器，对于这类中断，可以仅保存必要的寄存器，提高中断处理的效率，减少性能开销和资源浪费。



### 扩展练习 Challenge2：理解上下文切换机制

> 在 `trapentry.S` 中汇编代码 `csrw sscratch, sp；csrrw s0, sscratch, x0` 实现了什么操作，目的是什么？`save all` 里面保存了 `stval scause` 这些 `csr`，而在 `estore all` 里面却不还原它们？那这样 `store` 的意义何在呢？

1.  **`csrw sscratch, sp；csrrw s0, sscratch, x0` 实现了什么操作，目的是什么？**

   `csrw sscratch, sp` 将当前栈顶指针 `sp`  写入`sscratch` CSR 中，起到一个传递上下文信息的作用，便于中断处理程序处理相关信息。

   `csrrw s0, sscratch, x0` 将 `sscratch` 中的当前值读入到寄存器 `s0`，同时将 `x0`（值为0）写入 `sscratch`，RISCV 不能直接从 CSR 写到内存, 需要 csrr 把 CSR 读取到通用寄存器，再从通用寄存器 STORE 到内存，这里将 `sscratch` 写入寄存器 `s0` ，后续写入内存。而且在 `idt_init` 函数中，我们因为是内核态的中断而将 `sscratch` 置零，这里需要再次将 `sscratch` 置零。

2.  **`store` 的意义何在呢？**

   `SAVE_ALL` 中保存 `scause`、`sbadaddr` 等 CSR，是为了将这些相关的信息传递中断处理程序，尽在中断处理中使用，所以不需要还原。



### 扩展练习 Challenge3：完善异常中断

> 编程完善在触发一条非法指令异常 mret 和，在 kern/trap/trap.c的异常处理函数中捕获，并对其进行处理，简单输出异常类型和异常指令触发地址，即“Illegal instruction caught at 0x(地址)”，“ebreak caught at 0x（地址）”与“Exception type:Illegal instruction"，“Exception type: breakpoint”。（

只需在 trap.c 修改对应的异常处理程序，如

```
case CAUSE_ILLEGAL_INSTRUCTION:
    // 处理非法指令异常
    cprintf("Illegal instruction caught at 0x%08x\n", tf->epc);
    cprintf("Exception type: Illegal instruction\n");
    tf->epc += 4;
```

在 init.c 中可以测试我们的修改，在 `kern_init`  函数中加入

```
// 触发非法指令异常测试
// asm volatile(".word 0x00000000"); 

// 触发断点异常测试
// asm volatile("ebreak");
```

测试前请关闭循环设置时钟中断，或在时钟中断前进行。
