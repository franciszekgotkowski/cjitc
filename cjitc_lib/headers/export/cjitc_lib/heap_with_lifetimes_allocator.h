#pragma once

#include <stdint.h>
#include <stddef.h>

#define MAX_AMOUNT_OF_LIFETIMES 255
#define MAX_AMOUNT_OF_ALLOCATIONS 65535

typedef struct {
    int32_t next;
    void* ptr;
} AllocationMetadata;

void* HeapWithLifetimesAllocator_Initialize();
void HeapWithLifetimesAllocator_Denitialize(void* allocator);
void* HeapWithLifetimesAllocator_Alloc(size_t size, int32_t lifetime, void* allocator);
// void HeapWithLifetimesAllocator_Dealloc(void* ptr, void* allocator);
void HeapWithLifetimesAllocator_DeallocLifetime(uint32_t lifetime, void* allocator);

