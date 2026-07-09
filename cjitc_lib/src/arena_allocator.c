#include <memory_allocations.h>
#include <range.h>
#include <arena_allocator.h>
#include <assert.h>
#include <stddef.h>

ArenaAllocatorMetadata ArenaAllocator_Initialize() {
    ArenaAllocatorMetadata ret = (ArenaAllocatorMetadata) {
        .pageAllocationMetadata = {},
        .amountOfPageAllocations = 1
    };

    ret.pageAllocationMetadata[0] = (PageAllocationMetadata){
        .ptr = mem_alloc(DEFAULT_PAGE_ALLOCATION_SIZE),
        .size = DEFAULT_PAGE_ALLOCATION_SIZE
    };

    ret.stackTop = ret.pageAllocationMetadata[0].ptr;

    return ret;
}

void ArenaAllocator_Deinitialize(
    ArenaAllocatorMetadata* arena
) {
    assert(arena);

    for range(i, arena->amountOfPageAllocations) {
        mem_dealloc(
            arena->pageAllocationMetadata[i].ptr,
            arena->pageAllocationMetadata[i].size
        );
    }
}

static size_t getNewAllocationSize(
    size_t size
) {
    if (size % DEFAULT_PAGE_ALLOCATION_SIZE == 0) {
        return size;
    } else {
        return DEFAULT_PAGE_ALLOCATION_SIZE * (1 + size / DEFAULT_PAGE_ALLOCATION_SIZE);
    }
}

void* ArenaAllocator_Alloc(
    ArenaAllocatorMetadata* arena,
    size_t size,
    AllocatorError* err
) {
    assert(arena);
    assert(err);
    assert(arena->amountOfPageAllocations <= MAX_AMOUNT_OF_PAGE_ALLOCATIONS);
    assert(arena->amountOfPageAllocations >= 1);

    if (
        arena->amountOfPageAllocations == MAX_AMOUNT_OF_PAGE_ALLOCATIONS
    ) {
        if (
            arena->stackTop + size > 
            arena->pageAllocationMetadata[arena->amountOfPageAllocations-1].ptr + 
            arena->pageAllocationMetadata[arena->amountOfPageAllocations-1].size
        ) {
            *err = OUT_OF_SPACE;
            return NULL;
        }
    }

    if (
        arena->stackTop + size >
        arena->pageAllocationMetadata[arena->amountOfPageAllocations-1].ptr +
        arena->pageAllocationMetadata[arena->amountOfPageAllocations-1].size
    ) {
        arena->amountOfPageAllocations++;
        size_t allocationSize = getNewAllocationSize(size);
        arena->pageAllocationMetadata[arena->amountOfPageAllocations-1] = (PageAllocationMetadata) {
            .size = allocationSize,
            .ptr = mem_alloc(allocationSize)
        };
        arena->stackTop = arena->pageAllocationMetadata[arena->amountOfPageAllocations-1].ptr + size;
    } else {
        arena->stackTop += size;
    }

    *err = OK;
    return arena->stackTop - size;
}
