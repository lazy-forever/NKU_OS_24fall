## Lab 0.5

### 练习 1: 使用GDB验证启动流程

在本练习中，我们使用 GDB 调试 QEMU 模拟的 RISC-V 计算机，了解从加电到执行应用程序第一条指令（即跳转到 0x80200000）的过程。

在示例代码的 Makefile 中，定义了以下部分

```makefile
.PHONY: debug
debug: $(UCOREIMG) $(SWAPIMG) $(SFSIMG)
	$(V)$(QEMU) \
		-machine virt \
		-nographic \
		-bios default \
		-device loader,file=$(UCOREIMG),addr=0x80200000\
		-s -S
		
.PHONY: gdb
gdb:
	riscv64-unknown-elf-gdb \
    -ex 'file bin/kernel' \
    -ex 'set arch riscv:rv64' \
    -ex 'target remote localhost:1234'
```

于是可以使用 `make debug` 和 `make gdb` 对 QEMU 进行调试。`make debug` 完成内核镜像的生成和加载，启动 QEMU 时打开 GDB 监听端口，并暂停运行代码，等待 GDB 连接，提供了一个调试的起点。`make gdb` 让 GDB连接到监听端口，以进行远程调试。

我们在一个终端中，使用 `make debug` 启动 QEMU 并等待 GDB 连接；然后在另一个终端中，使用 `make gdb` 启动 GDB 并连接到 QEMU。GDB 启动后，可以看到

```
Reading symbols from bin/kernel...
The target architecture is set to "riscv:rv64".
Remote debugging using localhost:1234
0x0000000000001000 in ?? ()
```

其中“0x0000000000001000 in ?? ()”说明程序当前暂停在地址 `0x1000` 处。根据实验指导书，QEMU 模拟的 RISC-V 处理器的复位向量地址为 0x1000，处理器将从此处开始执行复位代码。因此 GDB 显示程序暂停在 `0x1000` 处是合理的。这也说明 GDB 确实是从程序最开始的地方开始调试。

然后使用 `x/10i $pc` 显示即将执行的 10 条汇编指令，得到

```assembly
(gdb) x/10i $pc
=> 0x1000:      auipc   t0,0x0
   0x1004:      addi    a1,t0,32
   0x1008:      csrr    a0,mhartid
   0x100c:      ld      t0,24(t0)
   0x1010:      jr      t0
   0x1014:      unimp
   0x1016:      unimp
   0x1018:      unimp
   0x101a:      0x8000
   0x101c:      unimp
```

可以看到在地址 ` 0x1010` 处存在一条跳转指令，目标地址在寄存器 `t0` 中。我们进行单步调试，并使用 `info r t0`  观察 `t0` 中的值。`auipc   t0,0x0` 将当前 PC 保存在 `t0` 中，`ld      t0,24(t0)` 将 `t0` 偏移 24 的地址，即 `0x1018` 中的数据加载到 `t0` 。使用 ` x/1xw 0x1018` 查看地址 `0x1018` 中的数据为 `0x80000000` ，执行该指令后 `t0` 中的数据为 `0x80000000` 。

实验指导书告诉我们，作为 bootloader 的 OpenSBI.bin 被加载到物理内存以物理地址 0x80000000 开头的区域上，说明当执行指令 `jr t0` 后，QEMU 模拟的 RISC-V 处理器将开始执行 OpenSBI.bin 程序。

使用 `x/10i $pc` 和单步调试 OpenSBI 程序，发现该程序较复杂。使用 `break *0x80200000` 在 `0x80200000` 处设置断点，然后 `continue` 执行到断点处。使用 `x/10i $pc` 观察，得到

```assembly
(gdb) x/10i $pc
=> 0x80200000 <kern_entry>:     auipc   sp,0x3
   0x80200004 <kern_entry+4>:   mv      sp,sp
   0x80200008 <kern_entry+8>:   j       0x8020000a <kern_init>
   0x8020000a <kern_init>:      auipc   a0,0x3
   0x8020000e <kern_init+4>:    addi    a0,a0,-2
   0x80200012 <kern_init+8>:    auipc   a2,0x3
   0x80200016 <kern_init+12>:   addi    a2,a2,-10
   0x8020001a <kern_init+16>:   addi    sp,sp,-16
   0x8020001c <kern_init+18>:   li      a1,0
   0x8020001e <kern_init+20>:   sub     a2,a2,a0
```

在 `/lab0/obj/kern/init` 中，存在编译得到的 `kernel.asm` 文件，查看该文件，其中 `kern_entry` 块等代码与 GDB 显示代码对应。这说明 `0x80200000` 确实是内核的起始地址。

**问题**

1. RISC-V 硬件加电后的几条指令在哪里？完成了哪些功能？

   RISC-V 硬件加电后，将要执行的指令在地址 `0x1000` 到地址 `0x1010` 处，在 `0x1010` 处将跳转到 `0x80000000` 执行 OpenSBI 程序。

   ```assembly
   0x1000:      auipc   t0,0x0
   0x1004:      addi    a1,t0,32
   0x1008:      csrr    a0,mhartid
   0x100c:      ld      t0,24(t0)
   0x1010:      jr      t0
   ```

   - ` auipc   t0,0x0` 将 `t0` 寄存器设置为 `0x1000`
   - `addi a1, t0, 32`  将`a1` 寄存器设置为 `0x1020`
   - `csrr a0, mhartid` 将 `a0` 寄存器设置为当前 hart 的ID，`mhartid`是机器硬件线程ID
   - `ld t0, 24(t0)` 将 `t0` 寄存器更新为内存地址 `0x1018` 处存储的值
   - `jr t0` 跳转到地址 `0x80000000`，开始执行 OpenSBI









