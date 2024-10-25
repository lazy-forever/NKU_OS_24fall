#include <pmm.h>
#include <list.h>
#include <string.h>
#include <buddy_system_pmm.h>

#define MAX_ORDER 11

free_area_t free_area[MAX_ORDER];

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