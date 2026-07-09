#pragma once

#include <stddef.h>
#include <stdint.h>

#define MAX_AMOUNT_OF_PAGE_ALLOCATIONS 255
#define DEFAULT_PAGE_ALLOCATION_SIZE (32*KB)

typedef enum {
    OK,
    OUT_OF_SPACE,

    AMOUNT_OF_ARENA_ALLOCATOR_ERRORS
} ArenaAllocatorError;

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
    ArenaAllocatorError* err
);
