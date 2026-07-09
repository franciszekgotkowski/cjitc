#pragma once

#include <stddef.h>
#include <stdint.h>
#include <stdbool.h>
#include <memory_allocations.h>
#include <allocator_errors.h>

// #define DEFAULT_PAGE_ALLOCATION_SIZE (32*KB)
// #define MAX_AMOUNT_OF_PAGES_FOR_LIFETIME 255
#define MAX_AMOUNT_OF_ARENA_LIFETIMES 255


// typedef struct {
// 	PageAllocationMetadata pageAllocationMetadata[MAX_AMOUNT_OF_ARENA_LIFETIMES];
// 	uint32_t amountOfPagesAllocated;
// 	bool active;
// 	void* lifetimeTop;
// } LifetimeMetadata ;

typedef struct {
	// LifetimeMetadata lifetimeMetadata[MAX_AMOUNT_OF_ARENA_LIFETIMES];
	uint32_t firstLifetimeInactive;
	uint32_t amountOfActiveLifetimes;
} MultiArenaAllocator;

MultiArenaAllocator ArenaAllocator_Initialize();
void ArenaAllocator_Denitialize(
	MultiArenaAllocator* allocator,
	AllocatorError* err
);
void* ArenaAllocator_Alloc(
	size_t size,
	int32_t lifetime,
	MultiArenaAllocator* allocator,
	AllocatorError* err
);
void ArenaAllocator_DeallocLifetime(
	uint32_t lifetime,
	MultiArenaAllocator* allocator,
	AllocatorError* err
);




