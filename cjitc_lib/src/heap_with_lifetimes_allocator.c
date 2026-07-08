#include <heap_with_lifetimes_allocator.h>
#include <range.h>
#include <stdint.h>

static AllocationMetadata allocationMetadata[MAX_AMOUNT_OF_ALLOCATIONS];
static int32_t unusedLifetimesQueue[MAX_AMOUNT_OF_LIFETIMES];

static void initializeAllocatorArrays() {
    for range(i, MAX_AMOUNT_OF_ALLOCATIONS) {
        allocationMetadata[i] = (AllocationMetadata){
            .next = i+1,
            .ptr = NULL
        };
    }
    allocationMetadata[MAX_AMOUNT_OF_ALLOCATIONS-1].next = -1;

    for range(i, MAX_AMOUNT_OF_ALLOCATIONS) {
   		unusedLifetimesQueue[i] = i;
    }
}

void* HeapWithLifetimesAllocator_Initialize() {
    initializeAllocatorArrays();

    return NULL;
}

void HeapWithLifetimesAllocator_Denitialize(void* allocator);

void* HeapWithLifetimesAllocator_Alloc(size_t size, int32_t lifetime, void* allocator);

// void HeapWithLifetimesAllocator_Dealloc(void* ptr, void* allocator);

void HeapWithLifetimesAllocator_DeallocLifetime(uint32_t lifetime, void* allocator);

