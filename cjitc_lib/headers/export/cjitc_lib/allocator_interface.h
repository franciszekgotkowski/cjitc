#pragma once

#include <stddef.h>
#include <stdint.h>

typedef void* PrototypeInitializeAllocator();
typedef void PrototypeDeinitializeAllocator(void* allocator);
typedef void* PrototypeAlloc(size_t size, int32_t lifetime, void* allocator);
typedef void PrototypeDealloc(void* ptr, void* allocator);
typedef void PrototypeDeallocLifetime(uint32_t lifetime, void* allocator);

void setupAllocatorFunctions(
    PrototypeInitializeAllocator* InitializeAllocator,
    PrototypeDeinitializeAllocator* DeinitializeAllocator,
    PrototypeAlloc* Alloc,
    // PrototypeDealloc* Dealloc,
    PrototypeDeallocLifetime* DeallocLifetime
);

PrototypeInitializeAllocator InitializeAllocator;
PrototypeDeinitializeAllocator DeinitializeAllocator;
PrototypeAlloc Alloc;
PrototypeDealloc Dealloc;
PrototypeDeallocLifetime DeallocLifetime;
