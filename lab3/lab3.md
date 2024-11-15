### 练习

对实验报告的要求：
 - 基于markdown格式来完成，以文本方式为主
 - 填写各个基本练习中要求完成的报告内容
 - 完成实验后，请分析ucore_lab中提供的参考答案，并请在实验报告中说明你的实现与参考答案的区别
 - 列出你认为本实验中重要的知识点，以及与对应的OS原理中的知识点，并简要说明你对二者的含义，关系，差异等方面的理解（也可能出现实验中的知识点没有对应的原理知识点）
 - 列出你认为OS原理中很重要，但在实验中没有对应上的知识点
 
#### 练习0：填写已有实验
本实验依赖实验1/2。请把你做的实验1/2的代码填入本实验中代码中有“LAB1”,“LAB2”的注释相应部分。

#### 练习1：理解基于FIFO的页面替换算法（思考题）
描述FIFO页面置换算法下，一个页面从被换入到被换出的过程中，会经过代码里哪些函数/宏的处理（或者说，需要调用哪些函数/宏），并用简单的一两句话描述每个函数在过程中做了什么？（为了方便同学们完成练习，所以实际上我们的项目代码和实验指导的还是略有不同，例如我们将FIFO页面置换算法头文件的大部分代码放在了`kern/mm/swap_fifo.c`文件中，这点请同学们注意）
 - 至少正确指出10个不同的函数分别做了什么？如果少于10个将酌情给分。我们认为只要函数原型不同，就算两个不同的函数。要求指出对执行过程有实际影响,删去后会导致输出结果不同的函数（例如assert）而不是cprintf这样的函数。如果你选择的函数不能完整地体现”从换入到换出“的过程，比如10个函数都是页面换入的时候调用的，或者解释功能的时候只解释了这10个函数在页面换入时的功能，那么也会扣除一定的分数

当我们需要换入 swap_in 一个页面时, `kern/mm/swap.c` 中的 `swap_in` 会完成页面换入的工作. 如果一个页需要被换入, 该页的页表项 PTE 通常已经被创建, 而对应的虚拟地址当前没有有效的物理映射. 因此无需创建页表项.

换入页面时, 首先需要调用 `alloc_page()` 为其分配 1 个物理页, 来存储从磁盘读取的数据. `alloc_page()` 是一个宏, 表示分配 1 个页 `alloc_pages(1)`. 

然后通过 `get_pte(mm->pgdir, addr, 0)` 查找虚拟地址 `addr` 对应的 PTE, 此时不需要创建页表项. 

获取 PTE 后, 调用 `swapfs_read()` , 从磁盘的交换空间读取页面内容, 并将数据加载到先前分配的物理页中. 

`ucore` 使用 **`alloc_pages`** 来分配 n 个连续的物理页, 其中分配方式由实现的页面分配算法决定，如 `first-fit` 或 `best-fit`. 

`/kern/mm/pmm.c` 中, `alloc_pages` 通过调用具体的 `pmm_manager->alloc_pages` 来在内存中分配物理页, 如果此时内存不足, 会调用 **`swap_out`** 来调用页面置换算法, 尝试换出 n 个页面, 以释放物理内存.

页面的换入由 `/kern/mm/swap.c` 中 `swap_out()` 完成. `swap_out()` 会调用具体的 `swap_manager` 实现的 **`swap_out_victim()`** 来从内存中选择一个页面进行换出, 换出对象的选择由实现的页面置换算法决定. 得到要换出的页的虚拟地址 `v` 后, 通过 **`get_pte(mm->pgdir, v, 0)`** 获取该地址在页表中的页表项, 然后调用 `swapfs_write()` 将要换出的页面 `page` 的数据写入磁盘的交换空间, 如果换出成功, 则使用 `free_page()` 来释放对应的物理页; 如果换出失败, 则使用 `map_swappable()` 将该页面标记为可换出页面.

对于基于 FIFO 的页面替换算法,  `swap_out()` 调用了 FIFO 算法的 `swap_out_victim()` 函数. 

```c
static int
_fifo_swap_out_victim(struct mm_struct *mm, struct Page ** ptr_page, int in_tick)
{
     list_entry_t *head=(list_entry_t*) mm->sm_priv;
         assert(head != NULL);
     assert(in_tick==0);
     /* Select the victim */
     //(1)  unlink the  earliest arrival page in front of pra_list_head qeueue
     //(2)  set the addr of addr of this page to ptr_page
    list_entry_t* entry = list_prev(head);
    if (entry != head) {
        list_del(entry);
        *ptr_page = le2page(entry, pra_page_link);
    } else {
        *ptr_page = NULL;
    }
    return 0;
}
```

要理解这个函数, 首先需要看看 FIFO 实现的其他部分. 在 `_fifo_init_mm()` 中, FIFO 算法完成初始化, 初始化时将 `mm->sm_priv` 设置为指向链表头部 `pra_list_head`. 而每次新增一个可交换页面时, 即在 `_fifo_map_swappable()` 中, 会将进入内存的页面加入链表的头部 `list_add(head, entry)` . 

因此在  `swap_out_victim()` 中, 根据 FIFO 思想: 最先进入内存的页面将最先被替换, 首先获取 FIFO 链表的头部, 然后使用 `list_prev(head)` 返回双向链表中头元素的前一个元素, 即链表的最后一个元素, 即"最早进入的页面". 

然后使用 `list_del(entry)` 从链表中删除受害者页面节点, 再通过 `le2page(entry, pra_page_link)` 宏将链表节点 `entry` 转换回其对应的 `Page` 结构体, 得到 `Page` 后即可进行后续操作, 完成物理页的查找和释放. 

页面的换出会不断进行, 直到 `alloc_pages` 能成功分配足够数量的物理页.

一个页面从被换入到被换出, 换入:

1. `alloc_page()` 为其分配 1 个物理页
2. `get_pte()` 根据虚拟地址 `addr` 查找该地址对应 PTE
3. ` swapfs_read()` 从磁盘的交换空间读取页面内容，并将数据加载到分配的物理页面中

当内存不足, 需要换出页面时: 

1. `alloc_pages()` 调用  `swap_out()`
2.  `swap_out()` 调用 `sm->swap_out_victim()` , 这是一个函数指针, 指向当前使用的页面置换算法的 `swap_out_victim` 函数, 如 ` _fifo_swap_out_victim()` 函数, 其中
   1. 获取 FIFO 链表头部 `pra_list_head` 
   2. 宏  `list_prev(head)` 返回双向链表中头元素的前一个元素, 即链表的最后一个元素
   3. 宏 `list_del(entry)` 从链表中删除受害者页面节点
   4. 宏  `le2page(entry, pra_page_link)` 宏将链表节点 `entry` 转换回其对应的 `Page` 结构体并返回
3. 得到要换出的页的虚拟地址 `v` 后, `get_pte(mm->pgdir, v, 0)` 获取该地址在页表中的页表项
4. `swapfs_write()` 将要换出的页面 `page` 的数据写入磁盘的交换空间
   - 成功:  `free_page()` 来释放对应的物理页
   - 失败:  `map_swappable()` 将该页面标记为可换出页面
     - 这里 `map_swappable()` 也是个函数指针, 这里指向 `_fifo_map_swappable` , 将可换出页面添加到链表头部.

#### 练习2：深入理解不同分页模式的工作原理（思考题）
get_pte()函数（位于`kern/mm/pmm.c`）用于在页表中查找或创建页表项，从而实现对指定线性地址对应的物理页的访问和映射操作。这在操作系统中的分页机制下，是实现虚拟内存与物理内存之间映射关系非常重要的内容。
 - get_pte()函数中有两段形式类似的代码， 结合sv32，sv39，sv48的异同，解释这两段代码为什么如此相像。
 - 目前get_pte()函数将页表项的查找和页表项的分配合并在一个函数里，你认为这种写法好吗？有没有必要把两个功能拆开？

#### 练习3：给未被映射的地址映射上物理页（需要编程）
补充完成do_pgfault（mm/vmm.c）函数，给未被映射的地址映射上物理页。设置访问权限 的时候需要参考页面所在 VMA 的权限，同时需要注意映射物理页时需要操作内存控制 结构所指定的页表，而不是内核的页表。
请在实验报告中简要说明你的设计实现过程。请回答如下问题：
 - 请描述页目录项（Page Directory Entry）和页表项（Page Table Entry）中组成部分对ucore实现页替换算法的潜在用处。
 - 如果ucore的缺页服务例程在执行过程中访问内存，出现了页访问异常，请问硬件要做哪些事情？
- 数据结构Page的全局变量（其实是一个数组）的每一项与页表中的页目录项和页表项有无对应关系？如果有，其对应关系是啥？

#### 练习4：补充完成Clock页替换算法（需要编程）
通过之前的练习，相信大家对FIFO的页面替换算法有了更深入的了解，现在请在我们给出的框架上，填写代码，实现 Clock页替换算法（mm/swap_clock.c）。
请在实验报告中简要说明你的设计实现过程。请回答如下问题：
 - 比较Clock页替换算法和FIFO算法的不同。

#### 练习5：阅读代码和实现手册，理解页表映射方式相关知识（思考题）
如果我们采用”一个大页“ 的页表映射方式，相比分级页表，有什么好处、优势，有什么坏处、风险？

#### 扩展练习 Challenge：实现不考虑实现开销和效率的LRU页替换算法（需要编程）
challenge部分不是必做部分，不过在正确最后会酌情加分。需写出有详细的设计、分析和测试的实验报告。完成出色的可获得适当加分。



