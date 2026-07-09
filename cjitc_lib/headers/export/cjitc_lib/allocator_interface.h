#pragma once

#include <stddef.h>
#include <stdint.h>
#include <multi_arena_allocator.h>
#include <allocator_errors.h>

typedef MultiArenaAllocator cjitc_allocator ;

typedef cjitc_allocator PrototypeInitializeAllocator();
typedef void PrototypeDeinitializeAllocator(
	cjitc_allocator* allocator,
	AllocatorError* err
);
typedef void* PrototypeAlloc(
	size_t size,
	int32_t lifetime,
	cjitc_allocator* allocator,
	AllocatorError* err
);
typedef void PrototypeDeallocLifetime(
	uint32_t lifetime,
	cjitc_allocator* allocator,
	AllocatorError* err
);
void setupAllocatorFunctions(
    PrototypeInitializeAllocator* InitializeAllocator,
    PrototypeDeinitializeAllocator* DeinitializeAllocator,
    PrototypeAlloc* Alloc,
    PrototypeDeallocLifetime* DeallocLifetime
);

PrototypeInitializeAllocator InitializeAllocator;
PrototypeDeinitializeAllocator DeinitializeAllocator;
PrototypeAlloc Alloc;
PrototypeDeallocLifetime DeallocLifetime;
