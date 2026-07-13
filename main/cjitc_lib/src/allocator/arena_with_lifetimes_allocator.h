#pragma once

#include <stddef.h>
#include <stdint.h>
#include <stdbool.h>
#include "allocator_errors.h"
#include "arena_allocator.h"

#define MAX_AMOUNT_OF_ARENA_LIFETIMES 256

typedef struct {
	ArenaAllocatorMetadata arenas[MAX_AMOUNT_OF_ARENA_LIFETIMES];
	bool isLifetimeActive[MAX_AMOUNT_OF_ARENA_LIFETIMES];
	uint32_t amountOfActiveLifetimes;
	uint32_t firstUnusedLifetime;
} ArenaWithLifetimesAllocator;

ArenaWithLifetimesAllocator ArenaWithLifetimesAllocator_Initialize();

void ArenaWithLifetimesAllocator_Denitialize(
	ArenaWithLifetimesAllocator* allocator
);

void* ArenaWithLifetimesAllocator_Alloc(
	size_t size,
	int32_t* lifetime,
	ArenaWithLifetimesAllocator* allocator,
	AllocatorError* err
);

void ArenaWithLifetimesAllocator_DeallocLifetime(
	int32_t lifetime,
	ArenaWithLifetimesAllocator* allocator,
	AllocatorError* err
);

bool ArenaWithLifetimesAllocator_isLifetimeActive(
	ArenaWithLifetimesAllocator* allocator,
	int32_t lifetime
);

int32_t ArenaWithLifetimesAllocator_amountOfActiveLifetimes(
	ArenaWithLifetimesAllocator* allocator
);

int32_t ArenaWithLifetimesAllocator_firstUnusedLifetime(
	ArenaWithLifetimesAllocator* allocator
);

