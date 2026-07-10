#pragma once

#include <stddef.h>
#include <stdint.h>
#include "arena_with_lifetimes_allocator.h"
#include "allocator_errors.h"

typedef ArenaWithLifetimesAllocator cjitc_allocator ;

// Function will return allocator struct that will manage the memory.
// Struct has to have size defined at compiletime
typedef cjitc_allocator PrototypeInitializeAllocator();

// Function will destroy allocator and all memory it allocated
typedef void PrototypeDeinitializeAllocator(
	cjitc_allocator* allocator
);

// This function will allow to allocate new memory.
// Each allocation has its own lifetime.
// If value pointed by lifetime == -1 a new lifetime will be assigned and lifetimes id will be put into address of lifetime pointer
// Lifetime id's are always non-negative
// Can return errors:
//	OK	-	if everything went fine
//	OUT_OF_LIFETIMES	-	if user wanted new lifetime but there are no filetimes left to distribute
//	LIFETIME_IS_INACTIVE	-	if user specified a lifetime but it was not active
//	OUT_OF_SPACE	-	if current allocator lifetime cannot allocate more memory. It doesn't mean that other lifetime could not allocate more
typedef void* PrototypeAlloc(
	size_t size,
	int32_t* lifetime,
	cjitc_allocator* allocator,
	AllocatorError* err
);

// Function will deallocate all memory managed by given lifetime
// Can return errors:
//	OK	-	if everything went fine
//	LIFETIME_IS_INACTIVE	-	if lifetime selected by user is inactive
typedef void PrototypeDeallocLifetime(
	uint32_t lifetime,
	cjitc_allocator* allocator,
	AllocatorError* err
);

// Before using library this function must be ran
// It will set up allocator functions which will be used by the library
void setupAllocatorFunctions(
    PrototypeInitializeAllocator* InitializeAllocator,
    PrototypeDeinitializeAllocator* DeinitializeAllocator,
    PrototypeAlloc* Alloc,
    PrototypeDeallocLifetime* DeallocLifetime
);

// This will run setupAllocatorFunctions with arena_allocator provided by this library
void setupDefaultAllocator();
void clearDefaultAllocator();

PrototypeInitializeAllocator InitializeAllocator;
PrototypeDeinitializeAllocator DeinitializeAllocator;
PrototypeAlloc Alloc;
PrototypeDeallocLifetime DeallocLifetime;
