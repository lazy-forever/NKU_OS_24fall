#ifndef __KERN_FS_FS_H__
#define __KERN_FS_FS_H__

#include <mmu.h>

#define SECTSIZE            512
#define PAGE_NSECT          (PGSIZE / SECTSIZE) // 一页需要 (4096 / 512 = 8) 个磁盘扇区

#define SWAP_DEV_NO         1 

#endif /* !__KERN_FS_FS_H__ */