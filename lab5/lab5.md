# Lab 5 用户程序

## 0 填写已有实验

> 实验依赖实验2/3/4，可能需对已完成的实验2/3/4的代码进行进一步改进。



## 1 加载应用程序并执行

> **do_execv**函数调用`load_icode`（位于kern/process/proc.c中）来加载并解析一个处于内存中的ELF执行文件格式的应用程序。你需要补充`load_icode`的第6步，建立相应的用户内存空间来放置应用程序的代码段、数据段等，且要设置好`proc_struct`结构中的成员变量trapframe中的内容，确保在执行此进程后，能够从应用程序设定的起始执行地址开始执行。需设置正确的trapframe内容。
>
> 请在实验报告中简要说明你的设计实现过程。
>
> - 请简要描述这个用户态进程被ucore选择占用CPU执行（RUNNING态）到具体执行应用程序第一条指令的整个经过。

### 1.1 实现过程

`load_icode` 函数的第六步中进行的是中断帧的设置，为了确保应用程序正确被加载需要进行如下设置：

1. 设置栈顶指针 (`gpr.sp`)：将 `gpr.sp` 设置为用户栈的顶部地址（`USTACKTOP`）。这样可以确保在用户程序运行时，程序能够正确地访问栈空间。
2. 设置程序计数器 (`epc`)：将 `epc` 设置为发生异常或中断时的程序计数器值，这个值应该是用户程序的入口点，即 ELF 文件头的 `e_entry`。在加载 ELF 文件时，ELF 头通过 `struct elfhdr *elf = (struct elfhdr *)binary;` 进行定义，`elf->e_entry` 就是程序的入口地址。将 `epc` 设置为该入口地址，可以确保用户程序从正确的位置开始执行。
3. 设置处理器状态信息 (`status`)：其中涉及两个关键状态位：`SSTATUS` 中的 `SPP` 和 `SPIE`：
   - SPP：表示处理器在发生异常或中断之前的特权级别。它有两个可能的值：0 表示处理器在异常或中断发生前处于用户模式（User Mode），1 表示处于特权模式（Supervisor Mode）。由于在系统调用 `sys_exec` 后，我们会调用 `sret` 指令返回到中断前的状态，因此为了确保 `sret` 返回到用户模式，`SPP` 应该设置为 0。
   - SPIE：表示处理器在异常或中断发生前的中断使能状态。它有两个可能的值：0 表示异常或中断发生前中断被禁用，1 表示中断被启用。为了确保用户模式下能够触发中断，因此应该启用中断，即将 `SPIE` 设置为 1。

补充 `load_icode` 函数如下：

```C
	// Set the user stack top
    tf->gpr.sp = USTACKTOP;
    // Set the entry point of the user program
    tf->epc = elf->e_entry;
    // Set the status register for the user program
    tf->status = (read_csr(sstatus) & ~SSTATUS_SPP) | SSTATUS_SPIE;
```



### 1.2 描述应用进程加载过程

在用户进程被 ucore 内核选择并调度执行时，实际上是通过操作系统的调度器从就绪队列中挑选出一个就绪的进程，然后通过进程切换来执行该进程。为了确保该进程能正确运行，内核需要进行一系列准备工作，具体操作如下：

#### 1.2.1 准备加载新的执行代码

首先，需要清空用户态内存空间，以准备加载新的执行代码。这个过程由 `do_execve` 实现，具体步骤如下：

- 判断进程的内存管理结构 (`mm`)：如果 `mm` 不为空，说明该进程是一个用户进程，此时需要将页表设置为内核页表，以便切换到内核态。
- 释放进程占用的内存：如果 `mm` 的引用计数为 1，意味着当前进程是唯一使用这块内存的进程。如果该进程终止，内存和进程页表将不再被其他进程使用，因此可以释放这些内存资源，以便其他进程使用。

#### 1.2.2. 加载应用程序执行代码并建立用户环境

接下来，内核需要完成以下任务，主要由 `load_icode` 实现：

- 读取 ELF 格式的执行文件：解析并加载用户程序的执行代码。
- 申请内存空间并建立用户态虚拟内存：
  - 调用 `mm_create` 为进程的内存管理数据结构 `mm` 分配内存并进行初始化。
  - 调用 `setup_pgdir` 为新的进程分配页目录表，并将内核页表的内容拷贝到新创建的页目录表中，从而保证能够正确映射内核虚拟地址空间。
  - 解析 ELF 文件，根据文件中的段信息调用 `mm_map`，将程序的各个段映射到进程的虚拟地址空间（即用户空间）。具体来说，`vma` 结构描述了用户程序的合法虚拟地址范围，并将这些 `vma` 插入到 `mm` 结构中。
  - 分配物理内存并在页表中建立虚拟地址到物理地址的映射关系，随后将执行文件的各个段加载到相应的内存位置。
  - 设置用户栈：调用 `mm_map` 创建栈的 `vma` 结构，栈位置被设定在用户虚拟地址空间的顶部，栈的大小为 256 页（即 1MB）。同时，分配相应的物理内存并完成虚拟地址到物理地址的映射。

#### 1.2.3. 更新用户进程的虚拟内存空间

此时，内核需要更新进程的虚拟内存空间。具体地，通过将 `mm->pgdir` 的值赋给 `cr3` 寄存器，来完成进程虚拟地址空间的切换。这样可以确保进程能够访问自己的虚拟内存空间。

#### 1.2.4. 建立进程的执行现场

最后，内核需要清空并重新设置进程的中断帧，以确保进程在执行中断返回指令 `iret` 后，能够正确地转入用户态。具体来说：

- 在执行 `iret` 后，CPU 将返回用户态特权级，并进入用户态的内存空间。
- 此时，CPU 将使用用户进程的代码段、数据段和堆栈。
- `iret` 指令还会使得程序跳转到用户进程的入口地址（即用户程序的第一条指令）。
- 在返回用户态时，进程也能响应外部中断和异常。



## 2 父进程复制自己的内存空间给子进程

> 创建子进程的函数`do_fork`在执行中将拷贝当前进程（即父进程）的用户内存地址空间中的合法内容到新进程中（子进程），完成内存资源的复制。具体是通过`copy_range`函数（位于kern/mm/pmm.c中）实现的，请补充`copy_range`的实现，确保能够正确执行。
>
> 请在实验报告中简要说明你的设计实现过程。
>
> - 如何设计实现`Copy on Write`机制？给出概要设计，鼓励给出详细设计。

### 2.1 补充 `copy_range` 函数

首先调用过程为：do_fork() --> copy_mm() --> dup_mmap() --> copy_range()

copy_range用于在内存页级别上复制一段地址范围的内容。

首先，它通过get_pte 函数获取源页表中的页表项，并检查其有效性。然后它在目标页表中获取或创建新的页表项，并为新的页分配内存。最后，它确保源页和新页都成功分配，并准备进行复制操作：

```C
            void *src_kvaddr = page2kva(page); // Get the kernel virtual address of the source page.
            void *dst_kvaddr = page2kva(npage); // Get the kernel virtual address of the destination page.
            memcpy(dst_kvaddr, src_kvaddr, PGSIZE); // Copy the content of the source page to the destination page.
            ret = page_insert(to, npage, start, perm); // Insert the destination page into the page table of the target process.
```

最后一行是使用前面的参数（to：目标进程的页目录地址，npage：页，start：起始地址，perm：提取出的页目录项 ptep 中的 PTE_USER 即用户级别权限相关的位）调用 page_insert 函数。



### 2.2 `Copy on Write` 的概要设计

1. 通过 `copy_range` 的 share 参数来设置是否共享，如果共享则不需要复制内存。
2. 对于写操作，如果已经是共享状态，可以通过内存保护硬件实现，当任务试图写入一个标记为只读的内存区域时，硬件触发一个异常。可以通过定义一个新的 trap 类型，使用 `trap.c` 的 exception_handler 中进行对应的处理。
3. 比如说分配新的内存，然后复制内容，之后更新指针，设置相应的标志。
4. 最后再进行写操作，这样就实现



## 3 理解进程执行 fork/exec/wait/exit 及系统调用

> 请在实验报告中简要说明你对 fork/exec/wait/exit 函数的分析。并回答如下问题：
>
> - 请分析fork/exec/wait/exit的执行流程。重点关注哪些操作是在用户态完成，哪些是在内核态完成？内核态与用户态程序是如何交错执行的？内核态执行结果是如何返回给用户程序的？
> - 请给出ucore中一个用户态进程的执行状态生命周期图（包执行状态，执行状态之间的变换关系，以及产生变换的事件或函数调用）。（字符方式画即可）

### 3.1 fork/exec/wait/exit 分析

用户态和内核态的切换主要发生在系统调用。当进程执行系统调用时，会从用户态切换到内核态，内核执行相应的操作，然后再切换回用户态，将执行结果返回给用户程序。fork 、exec 、wait 、exit 等系统调用都会引起用户态到内核态的切换。

1. fork：创建子进程

   调用过程：fork --> SYS_fork --> do_fork --> wakeup_proc

   用户态：父进程调用 fork() 系统调用。
   内核态：内核复制父进程的所有资源（内存、文件描述符等），创建一个新的子进程。
   用户态：子进程从 fork 调用返回，得到一个新的进程ID（PID），父进程也从 fork 调用返回，得到子进程的PID。

2. exec：进程执行

   调用过程：exec --> SYS_exec --> do_execve

   用户态：进程调用 exec 系统调用，加载并执行新的程序。
   内核态：内核加载新程序的代码和数据，并进行一些必要的初始化。
   用户态：新程序开始执行，原来的程序替换为新程序。

3. wait：等待进程

   调用过程：wait --> SYS_wait --> do_wait

   用户态：父进程调用 wait 或 waitpid 系统调用等待子进程的退出。
   内核态：如果子进程已经退出，内核返回子进程的退出状态给父进程；如果子进程尚未退出，父进程被阻塞，等待子进程退出。
   用户态：父进程得到子进程的退出状态，可以进行相应的处理。

4. exit：进程退出

   调用过程：exit --> SYS_exit --> do_exit

   用户态：进程调用 exit 系统调用，通知内核准备退出。
   内核态：内核清理进程资源，包括释放内存、关闭文件等。
   用户态：进程退出，返回到父进程。

   

### 3.2 用户进程的生命周期图

```
父进程 --fork-- 子进程(创建) --exec-- 子进程(执行) --exit-- 子进程(退出)--wakeup--父进程
父进程 --wait-- 立即返回或阻塞（等待子进程退出）返回
```



## C1 实现 Copy on Write (COW) 机制

> 给出实现源码,测试用例和设计报告（包括在cow情况下的各种状态转换（类似有限状态自动机）的说明）。

未实现。



## C2 理解用户程序加载过程

> 说明该用户程序是何时被预先加载到内存中的？与我们常用操作系统的加载有何区别，原因是什么？

### C2.1 用户程序预先加载到内存的时机

```makefile
$(kernel): $(KOBJS) $(USER_BINS)
	@echo + ld $@
	$(V)$(LD) $(LDFLAGS) -T tools/kernel.ld -o $@ $(KOBJS) --format=binary $(USER_BINS) --format=default
	@$(OBJDUMP) -S $@ > $(call asmfile,kernel)
	@$(OBJDUMP) -t $@ | $(SED) '1,/SYMBOL TABLE/d; s/ .* / /; /^$$/d' > $(call symfile,kernel)
```

内核目标文件（`$(kernel)`）依赖于内核的对象文件（`$(KOBJS)`）和用户程序的二进制文件（`$(USER_BINS)`）。

内核和用户程序的二进制文件通过链接器（`$(LD)`）一起被链接到最终的二进制镜像文件中，形成一个可执行的内核映像。

通过 make file 中的 make 文件里面最后一步的 ld 命令加载的，用户程序连接在了 ucore kernel 的末尾。
而对于一般的应用程序，会在需要时被加载到内存中。这个加载的过程通常是动态的，而不是一开始就将整个程序加载到内存中。



### C2.2 与常用操作系统加载的区别

在常见的操作系统中应用程序并不是在系统启动时就被加载到内存中。相反，当用户需要运行某个应用程序时，操作系统才会将其加载到内存中。这种方式被称为延迟加载或按需加载。

延迟加载的优点是，它可以有效地管理系统资源，特别是内存。如果操作系统在启动时就将所有可能需要的应用程序都加载到内存中，那么很快就会耗尽内存资源。而通过延迟加载，操作系统可以确保只有真正需要运行的应用程序才会占用内存资源。
而本次实验中 exit 应用程序是和 ucore 一起被加载到内存中，而不是一种动态的加载方式，而是静态的在系统启动时就被加载到内存中。

### C2.3 原因

因为用户应用程序是要紧跟着内核的第二个线程 init_proc 执行的，所以它其实在系统一启动就执行了。而不是后面通过调度选择它来执行，由于我们本次实验不涉及到不同用户态应用程序的调度也没有实现，我们不能在后期动态加载这个程序，所以就和 ucore 内核一起在启动时就加载了。方便启动时不使用调度而直接执行。

