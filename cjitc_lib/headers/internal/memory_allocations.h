#pragma once

#include <stddef.h>

#define KB ((u64)1024)
#define MB ((u64)KB*1024)
#define GB ((u64)MB*1024)

#define BASE_POOL_ADDRESS 0x600000000000

// allocates memory via system calls
void* mem_alloc(size_t size);
void* mem_alloc_on_address(size_t size, void* address);
void mem_dealloc(void* ptr, size_t size);

