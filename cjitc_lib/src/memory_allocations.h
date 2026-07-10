#pragma once

#include <stddef.h>

#define KB ((size_t)1024)
#define MB ((size_t)KB*1024)
#define GB ((size_t)MB*1024)

// allocates memory via system calls
void* mem_alloc(size_t size);
void* mem_alloc_on_address(size_t size, void* address);
void mem_dealloc(void* ptr, size_t size);

