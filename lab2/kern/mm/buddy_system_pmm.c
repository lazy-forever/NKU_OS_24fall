#include <pmm.h>
#include <list.h>
#include <string.h>
#include <buddy_system_pmm.h>
#include <stdio.h>

#define MAX_ORDER 11

extern free_area_t free_area[MAX_ORDER];

#define free_list(i) (free_area[i].free_list)
#define nr_free(i) (free_area[i].nr_free)

static void
buddy_system_init(void) {
    for (int i = 0; i < MAX_ORDER; i++) {
        list_init(&free_list(i));
        nr_free(i) = 0;
    }
}

static void
buddy_system_init_memmap(struct Page *base, size_t n) {
    assert(n > 0);
    struct Page *p = base;
    for (; p != base + n; p++) {
        assert(PageReserved(p));
        p->flags = p->property = 0;
        set_page_ref(p, 0);
    }
    p = base;
    size_t rest_size = n;
    for (int i = MAX_ORDER - 1; i >= 0; i--) {
        size_t block_size = 1 << i;
        while (rest_size >= block_size) {
            p->property = block_size;
            SetPageProperty(p);
            nr_free(i)++;
            list_add(&free_list(i), &(p->page_link));
            p += block_size;
            rest_size -= block_size;
        }
    }
}

static struct Page *
buddy_system_alloc_pages(size_t n) {
    assert(n > 0);
    int order = 0;
    while ((1 << order) < n) {
        order++;
    }
    for (int i = order; i < MAX_ORDER; i++) {
        if (nr_free(i) > 0) {
            struct Page *page = le2page(list_next(&free_list(i)), page_link);
            list_del(&(page->page_link));
            ClearPageProperty(page);
            nr_free(i)--;
            while (i > order) {
                i--;
                // 创建 buddy 页，将它设置为高阶页的后一半
                struct Page *buddy_page = page + (1 << i);
                // 将 buddy 页加入低阶空闲列表
                buddy_page->property = 1 << i;
                SetPageProperty(buddy_page);
                nr_free(i)++;
                list_add(&free_list(i), &(buddy_page->page_link));
            }
            return page;
        }
    }
    return NULL;
}

static void
buddy_system_free_pages(struct Page *base, size_t n) {
    assert(n > 0);
    struct Page *p = base;
    for (; p != base + n; p++) {
        assert(!PageReserved(p) && !PageProperty(p));
        p->flags = 0;
        set_page_ref(p, 0);
    }
    p = base;
    int order = 0;
    while ((1 << order) < n) {
        order++;
    }
    while (1) {
        size_t buddy_idx = page2ppn(p) ^ (1 << order); //伙伴页的索引
        struct Page *buddy_page = pa2page(buddy_idx << PGSHIFT); //伙伴页
        if (order >= MAX_ORDER || buddy_idx >= npage || buddy_page->property != (1 << order) || PageProperty(buddy_page)) {
            p->property = 1 << order;
            SetPageProperty(p);
            nr_free(order)++;
            list_add(&free_list(order), &(p->page_link));
            break;
        }
        // list_entry_t *le = &(buddy_page->page_link);
        // if (le != &free_list(order)) {
        //     list_del(le);
        // }
        list_del(&(buddy_page->page_link));
        ClearPageProperty(buddy_page);
        nr_free(order)--;
        p = (p < buddy_page) ? p : buddy_page;
        order++;
    }
}

static size_t
buddy_system_nr_free_pages(void) {
    size_t ret = 0;
    for (int i = 0; i < MAX_ORDER; i++) {
        ret += nr_free(i) * (1 << i);
    }
    return ret;
}

static void
basic_check(void) {
    struct Page *p0, *p1, *p2;
    p0 = p1 = p2 = NULL;
    assert((p0 = buddy_system_alloc_pages(1)) != NULL);
    assert((p1 = buddy_system_alloc_pages(1)) != NULL);
    assert((p2 = buddy_system_alloc_pages(1)) != NULL);

    assert(p0 != p1 && p0 != p2 && p1 != p2);
    assert(page_ref(p0) == 0 && page_ref(p1) == 0 && page_ref(p2) == 0);

    // 确保物理地址有效
    assert(page2pa(p0) < npage * PGSIZE);
    cprintf("p0: 0x%016x\n", page2pa(p0));
    assert(page2pa(p1) < npage * PGSIZE);
    cprintf("p1: 0x%016x\n", page2pa(p1));
    assert(page2pa(p2) < npage * PGSIZE);
    cprintf("p2: 0x%016x\n", page2pa(p2));

    // 保存当前的空闲列表
    free_area_t free_area_store[MAX_ORDER];
    memcpy(free_area_store, free_area, sizeof(free_area));

    // 清空空闲列表
    buddy_system_init();
    for (int i = 0; i < MAX_ORDER; i++) {
        assert(list_empty(&free_list(i)));
    }
    
    // 确保无法分配任何页
    assert(buddy_system_alloc_pages(1) == NULL);

    // 释放并检查
    buddy_system_free_pages(p0, 1);
    buddy_system_free_pages(p1, 1);
    buddy_system_free_pages(p2, 1);

    assert(buddy_system_nr_free_pages() == 3);

    // 再次分配
    assert((p0 = buddy_system_alloc_pages(1)) != NULL);
    assert((p1 = buddy_system_alloc_pages(1)) != NULL);
    assert((p2 = buddy_system_alloc_pages(1)) != NULL);

    assert(buddy_system_alloc_pages(1) == NULL);

    // 释放一个页，检查空闲列表不为空
    buddy_system_free_pages(p0, 1);
    int found_free_page = 0;
    for (int i = 0; i < MAX_ORDER; i++) {
        if (!list_empty(&free_list(i))) {
            found_free_page = 1;
            break;
        }
    }
    assert(found_free_page);

    // 再次分配，确保分配的是刚刚释放的页
    struct Page *p;
    assert((p = buddy_system_alloc_pages(1)) == p0);
    assert(buddy_system_alloc_pages(1) == NULL);

    // 确保没有空闲页
    assert(buddy_system_nr_free_pages() == 0);

    // 恢复空闲页链表
    memcpy(free_area, free_area_store, sizeof(free_area));

    // 释放最后分配的页
    buddy_system_free_pages(p, 1);
    buddy_system_free_pages(p1, 1);
    buddy_system_free_pages(p2, 1);
}

static void
default_check(void) {
    int total = 0;

    // 遍历所有阶的空闲页链表，检查每个页的属性
    for (int i = 0; i < MAX_ORDER; i++) {
        list_entry_t *le = &free_list(i);
        while ((le = list_next(le)) != &free_list(i)) {
            struct Page *p = le2page(le, page_link);
            assert(PageProperty(p));
            total += p->property;
        }
    }
    
    // 确保计算的空闲页数量与全局空闲页总数一致
    assert(total == buddy_system_nr_free_pages());

    // 调用基本检查函数
    basic_check();

    // 测试分配 8 个页
    struct Page *p0 = buddy_system_alloc_pages(8), *p1;
    assert(p0 != NULL);
    assert(!PageProperty(p0));

    // 保存当前的空闲页链表
    free_area_t free_area_store[MAX_ORDER];
    memcpy(free_area_store, free_area, sizeof(free_area));

    // 清空空闲页链表
    buddy_system_init();
    for (int i = 0; i < MAX_ORDER; i++) {
        assert(list_empty(&free_list(i)));
    }
    
    // 确保无法分配任何页
    assert(buddy_system_alloc_pages(1) == NULL);

    // 测试释放部分页
    buddy_system_free_pages(p0 + 4, 4);
    
    assert(buddy_system_alloc_pages(8) == NULL);
    assert(PageProperty(p0 + 4) && p0[4].property == 4);

    // 测试分配 4 个页
    assert((p1 = buddy_system_alloc_pages(4)) != NULL);
    assert(buddy_system_alloc_pages(1) == NULL);
    assert(p0 + 4 == p1);

    // 全部释放分配的页
    buddy_system_free_pages(p0, 4);
    buddy_system_free_pages(p1, 4);

    // 遍历检查，确保释放后计数正确
    total = 0;
    for (int i = 0; i < MAX_ORDER; i++) {
        list_entry_t *le = &free_list(i);
        while ((le = list_next(le)) != &free_list(i)) {
            struct Page *p = le2page(le, page_link);
            total += p->property;
        }
    }

    // 确保计算的空闲页数量与全局空闲页总数一致
    assert(total == buddy_system_nr_free_pages());
}

//这个结构体在
const struct pmm_manager buddy_system_pmm_manager = {
    .name = "buddy_pmm_manager",
    .init = buddy_system_init,
    .init_memmap = buddy_system_init_memmap,
    .alloc_pages = buddy_system_alloc_pages,
    .free_pages = buddy_system_free_pages,
    .nr_free_pages = buddy_system_nr_free_pages,
    .check = default_check,
};