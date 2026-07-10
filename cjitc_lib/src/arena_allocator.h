#pragma once

#include <stddef.h>
#include <stdint.h>
#include "allocator_errors.h"

#ifndef KB
    #define KB 1024
#endif


#define MAX_AMOUNT_OF_PAGE_ALLOCATIONS 256
#define DEFAULT_PAGE_ALLOCATION_SIZE (32*KB)

typedef struct {
    size_t size;
    void* ptr;
} PageAllocationMetadata ;

typedef struct {
    PageAllocationMetadata pageAllocationMetadata[MAX_AMOUNT_OF_PAGE_ALLOCATIONS];
    uint32_t amountOfPageAllocations;
    void* stackTop;
} ArenaAllocatorMetadata;

ArenaAllocatorMetadata ArenaAllocator_Initialize();

void ArenaAllocator_Deinitialize(
    ArenaAllocatorMetadata* arena
);

void* ArenaAllocator_Alloc(
    ArenaAllocatorMetadata* arena,
    size_t size,
    AllocatorError* err
);
