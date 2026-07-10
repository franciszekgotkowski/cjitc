#include "arena_with_lifetimes_allocator.h"
#include "allocator_errors.h"
#include <assert.h>

ArenaWithLifetimesAllocator ArenaWithLifetimesAllocator_Initialize() {
    ArenaWithLifetimesAllocator arenaWithLifetimesAllocator = (ArenaWithLifetimesAllocator) {
        .isLifetimeActive = {},
        .amountOfActiveLifetimes = 0,
        .firstUnusedLifetime = 0
    };
    return arenaWithLifetimesAllocator;
}

void ArenaWithLifetimesAllocator_Denitialize(
	ArenaWithLifetimesAllocator* allocator
) {
	assert(allocator);

	for (
		int32_t i = 0;
		allocator->amountOfActiveLifetimes > 0 &&
		i < MAX_AMOUNT_OF_ARENA_LIFETIMES;
		i++
	) {
		if (allocator->isLifetimeActive[i]) {
			allocator->isLifetimeActive[i] = false;
			allocator->amountOfActiveLifetimes--;
			ArenaAllocator_Deinitialize(
				&allocator->arenas[i]
			);
		}
	}
}

static int32_t getNewLifetime(
	ArenaWithLifetimesAllocator* alloc,
	AllocatorError* err
) {
	assert(alloc);
	assert(err);

	if (alloc->amountOfActiveLifetimes == MAX_AMOUNT_OF_ARENA_LIFETIMES) {
		*err = OUT_OF_LIFETIMES;
		return -1;
	}

	int32_t ourLifetime = alloc->firstUnusedLifetime;
	alloc->isLifetimeActive[ourLifetime] = true;

	int32_t inactiveLifetime;
	for (inactiveLifetime = alloc->firstUnusedLifetime; alloc->isLifetimeActive[inactiveLifetime] == true; inactiveLifetime++) {}
	alloc->firstUnusedLifetime = inactiveLifetime;
	alloc->amountOfActiveLifetimes++;

	*err = OK;
	return ourLifetime;
}

void* ArenaWithLifetimesAllocator_Alloc(
	size_t size,
	int32_t* lifetime,
	ArenaWithLifetimesAllocator* allocator,
	AllocatorError* err
) {
	assert(*lifetime >= -1 && *lifetime < MAX_AMOUNT_OF_ARENA_LIFETIMES);
	assert(lifetime);
	assert(allocator);
	assert(err);

	AllocatorError e = UNKNOWN;

	int32_t ourLifetime;
	if ( *lifetime == -1) {
		ourLifetime = getNewLifetime(
			allocator, &e
		);
		if (e != OK) {
			assert(e == OUT_OF_LIFETIMES);
			*err = e;
			return NULL;
		}
		allocator->arenas[ourLifetime] = ArenaAllocator_Initialize();

	} else {

		if (allocator->isLifetimeActive[*lifetime] == false) {
			*err = LIFETIME_IS_INACTIVE;
			return NULL;
		}

		ourLifetime = *lifetime;
	}

	void* ptr = ArenaAllocator_Alloc(
		&allocator->arenas[ourLifetime],
		size,
		&e
	);

	if (e != OK) {
		*err = e;
		return NULL;
	}
	*lifetime = ourLifetime;

	*err = OK;
	return ptr;
}

void ArenaWithLifetimesAllocator_DeallocLifetime(
	uint32_t lifetime,
	ArenaWithLifetimesAllocator* allocator,
	AllocatorError* err
) {
	assert(lifetime >= 0 && lifetime < MAX_AMOUNT_OF_ARENA_LIFETIMES);
	assert(allocator);
	assert(err);

	if (allocator->isLifetimeActive[lifetime] == false) {
		*err = LIFETIME_IS_INACTIVE;
		return;
	}

	allocator->amountOfActiveLifetimes--;
	if (lifetime < allocator->firstUnusedLifetime) {
		allocator->firstUnusedLifetime = lifetime;
	}

	allocator->isLifetimeActive[lifetime] = false;
	ArenaAllocator_Deinitialize(
		&allocator->arenas[lifetime]
	);
	*err = OK;
}




