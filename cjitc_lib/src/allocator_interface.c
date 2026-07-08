#include <allocator_interface.h>
#include <assert.h>

PrototypeInitializeAllocator* ptr_InitializeAllocator = NULL;
PrototypeDeinitializeAllocator* ptr_DeinitializeAllocator = NULL;
PrototypeAlloc* ptr_Alloc = NULL;
PrototypeDealloc* ptr_Dealloc = NULL;
PrototypeDeallocLifetime* ptr_DeallocLifetime = NULL;

void setupAllocatorFunctions(
    PrototypeInitializeAllocator* InitializeAllocator,
    PrototypeDeinitializeAllocator* DeinitializeAllocator,
    PrototypeAlloc* Alloc,
    // PrototypeDealloc* Dealloc,
    PrototypeDeallocLifetime* DeallocLifetime
) {
    assert(ptr_InitializeAllocator);
    assert(ptr_DeinitializeAllocator);
    assert(ptr_InitializeAllocator);
    // assert(ptr_Dealloc);
    assert(ptr_DeallocLifetime);

    ptr_InitializeAllocator = InitializeAllocator;
    ptr_DeinitializeAllocator = DeinitializeAllocator;
    ptr_Alloc = Alloc;
    // ptr_Dealloc = Dealloc;
    ptr_DeallocLifetime = DeallocLifetime;
}

void* InitializeAllocator() {
    assert(ptr_InitializeAllocator);
    return ptr_InitializeAllocator();
}

void DeinitializeAllocator(void* allocator) {
    assert(ptr_DeinitializeAllocator);
    return ptr_DeinitializeAllocator(allocator);
}

void* Alloc(size_t size, int32_t lifetime, void* allocator) {
    assert(ptr_Alloc);
    return ptr_Alloc(size, lifetime, allocator);
}

void Dealloc(void* ptr, void* allocator) {
    assert(ptr_Dealloc);
    return ptr_Dealloc(ptr, allocator);
}

void DeallocLifetime(uint32_t lifetime, void* allocator) {
    assert(ptr_DeallocLifetime);
    return ptr_DeallocLifetime(lifetime, allocator);
}
