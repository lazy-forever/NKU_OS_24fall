#include <defs.h>
#include <riscv.h>
#include <stdio.h>
#include <string.h>
#include <swap.h>
#include <swap_lru.h>
#include <list.h>
#include <pmm.h>

extern list_entry_t pra_list_head, *curr_ptr;

/*
 * (2) _lru_init_mm: init pra_list_head and let mm->sm_priv point to the addr of pra_list_head.
 * Now, from the memory control struct mm_struct, we can access LRU PRA
 */
static int
_lru_init_mm(struct mm_struct *mm)
{     
    // 初始化pra_list_head为空链表
    list_init(&pra_list_head);
    // 初始化当前指针curr_ptr指向pra_list_head，表示当前页面替换位置为链表头
    curr_ptr = &pra_list_head;
    // 将mm的私有成员指针指向pra_list_head，用于后续的页面替换算法操作
    mm->sm_priv = &pra_list_head;

    return 0;
}

/*
 * (3)_lru_map_swappable: According to LRU PRA, we should move the most recent arrival page to the front of pra_list_head queue
 */
static int
_lru_map_swappable(struct mm_struct *mm, uintptr_t addr, struct Page *page, int swap_in)
{
    list_entry_t *entry = &(page->pra_page_link);
    list_entry_t *head = (list_entry_t*) mm->sm_priv;
    list_entry_t *curr;

    assert(entry != NULL && head != NULL);

    curr = list_next(head);  // 从第一个元素开始遍历
    while (curr != head) {
        struct Page *curr_page = le2page(curr, pra_page_link);
        if (curr_page == page) {
            // 如果页面已经在链表中，先将其删除
            list_del(curr);
            break;
        }
        curr = list_next(curr);
    }


    // 将页面插入到链表的开头，表示它是最新访问的
    list_add_before(head, entry);
    
    // 设置页面的虚拟地址并标记为已访问
    page->pra_vaddr = addr;
    page->visited = 1;
    
    return 0;
}

/*
 * (4)_lru_swap_out_victim: According to LRU PRA, we should unlink the least recently used page at the end of pra_list_head queue
 */
static int
_lru_swap_out_victim(struct mm_struct *mm, struct Page **ptr_page, int in_tick)
{
    list_entry_t *head = (list_entry_t*) mm->sm_priv;
    assert(head != NULL);
    assert(in_tick == 0);

    /* 选择换出页面 */
    //(1) 遍历链表，找到最久未访问的页面，通常是链表末尾的页面
    //(2) 将该页面从链表中删除并设置为换出的页面
    
    // curr_ptr 指向链表的尾部，即最久未访问的页面
    curr_ptr = list_prev(head);
    
    struct Page *page = le2page(curr_ptr, pra_page_link);
    
    // 从链表中删除该页面，并将其设置为换出的页面
    list_del(curr_ptr);
    *ptr_page = page;
    
    return 0;
}


static int
_lru_check_swap(void) {
    //swap_tick_event(check_mm_struct);

    cprintf("write Virt Page c in lru_check_swap\n");
    *(unsigned char *)0x3000 = 0x0c;
    assert(pgfault_num==4);
    cprintf("write Virt Page a in lru_check_swap\n");
    *(unsigned char *)0x1000 = 0x0a;
    assert(pgfault_num==4);
    cprintf("write Virt Page d in lru_check_swap\n");
    *(unsigned char *)0x4000 = 0x0d;
    assert(pgfault_num==4);
    cprintf("write Virt Page b in lru_check_swap\n");
    *(unsigned char *)0x2000 = 0x0b;
    assert(pgfault_num==4);
    cprintf("write Virt Page e in lru_check_swap\n");
    *(unsigned char *)0x5000 = 0x0e;
    assert(pgfault_num==5);
    cprintf("write Virt Page b in lru_check_swap\n");
    *(unsigned char *)0x2000 = 0x0b;
    assert(pgfault_num==5);
    cprintf("write Virt Page a in lru_check_swap\n");
    *(unsigned char *)0x1000 = 0x0a;
    assert(pgfault_num==6);
    cprintf("write Virt Page b in lru_check_swap\n");
    *(unsigned char *)0x2000 = 0x0b;
    assert(pgfault_num==7);
    cprintf("write Virt Page c in lru_check_swap\n");
    *(unsigned char *)0x3000 = 0x0c;
    assert(pgfault_num==8);
    cprintf("write Virt Page d in lru_check_swap\n");
    *(unsigned char *)0x4000 = 0x0d;
    assert(pgfault_num==9);
    cprintf("write Virt Page e in lru_check_swap\n");
    *(unsigned char *)0x5000 = 0x0e;
    assert(pgfault_num==10);
    cprintf("write Virt Page a in lru_check_swap\n");
    assert(*(unsigned char *)0x1000 == 0x0a);
    *(unsigned char *)0x1000 = 0x0a;
    assert(pgfault_num==11);

    cprintf("LRU test passed!\n");
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
     .name            = "lru swap manager",
     .init            = &_lru_init,
     .init_mm         = &_lru_init_mm,
     .tick_event      = &_lru_tick_event,
     .map_swappable   = &_lru_map_swappable,
     .set_unswappable = &_lru_set_unswappable,
     .swap_out_victim = &_lru_swap_out_victim,
     .check_swap      = &_lru_check_swap,
};