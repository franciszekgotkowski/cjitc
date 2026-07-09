#include <allocator_interface.h>
#include <arena_with_lifetimes_allocator.h>
#include <assert.h>

PrototypeInitializeAllocator *ptr_InitializeAllocator = NULL;
PrototypeDeinitializeAllocator *ptr_DeinitializeAllocator = NULL;
PrototypeAlloc *ptr_Alloc = NULL;
PrototypeDeallocLifetime *ptr_DeallocLifetime = NULL;

void setupAllocatorFunctions(
    PrototypeInitializeAllocator *InitializeAllocator,
    PrototypeDeinitializeAllocator *DeinitializeAllocator,
    PrototypeAlloc *Alloc,
    PrototypeDeallocLifetime *DeallocLifetime
) {
    assert(InitializeAllocator);
    assert(DeinitializeAllocator);
    assert(InitializeAllocator);
    assert(DeallocLifetime);

    ptr_InitializeAllocator = InitializeAllocator;
    ptr_DeinitializeAllocator = DeinitializeAllocator;
    ptr_Alloc = Alloc;
    ptr_DeallocLifetime = DeallocLifetime;
}

void clearDefaultAllocator(
) {
    ptr_InitializeAllocator = NULL;
    ptr_DeinitializeAllocator = NULL;
    ptr_Alloc = NULL;
    ptr_DeallocLifetime = NULL;
}

void setupDefaultAllocator() {
    setupAllocatorFunctions(
        &ArenaWithLifetimesAllocator_Initialize,
        &ArenaWithLifetimesAllocator_Denitialize,
        &ArenaWithLifetimesAllocator_Alloc,
        &ArenaWithLifetimesAllocator_DeallocLifetime
    );
}

cjitc_allocator InitializeAllocator() {
    assert(ptr_InitializeAllocator);
    return ptr_InitializeAllocator();
}

void DeinitializeAllocator(
    cjitc_allocator *allocator
) {
    assert(ptr_DeinitializeAllocator);

    return ptr_DeinitializeAllocator(allocator);
}

void *Alloc(
    size_t size,
    int32_t *lifetime,
    cjitc_allocator *allocator,
    AllocatorError *err
) {
    assert(ptr_Alloc);
    assert(err);
    assert(*lifetime >= -1);
    assert(lifetime);

    return ptr_Alloc(
        size,
        lifetime,
        allocator,
        err
    );
}

void DeallocLifetime(
    uint32_t lifetime,
    cjitc_allocator *allocator,
    AllocatorError *err
) {
    assert(ptr_DeallocLifetime);
    assert(err);
    assert(lifetime >= -1);

    return ptr_DeallocLifetime(
        lifetime,
        allocator,
        err
    );
}
