#include <allocator_errors.h>
#include <assert.h>
#include <stdint.h>
#include <stddef.h>
#include <allocator_interface.h>
#include <multi_arena_allocator.h>
#include <range.h>

MultiArenaAllocator ArenaAllocator_Initialize() {
	MultiArenaAllocator ret = (MultiArenaAllocator){
		.firstLifetimeInactive = 0,
		.amountOfActiveLifetimes = 0
	};

	for range(i, MAX_AMOUNT_OF_ARENA_LIFETIMES) {
	ret.lifetimeMetadata[i] = (LifetimeMetadata) {
		.amountOfPagesAllocated = 0,
		.active = false
	};
}

return ret;
}

void ArenaAllocator_Denitialize(
	MultiArenaAllocator* allocator,
	AllocatorError* err
) {}

void* ArenaAllocator_Alloc(
	size_t size,
	int32_t lifetime,
	MultiArenaAllocator* allocator,
	AllocatorError* err
) {
	assert(allocator);
	assert(lifetime >= -1);

}

void ArenaAllocator_DeallocLifetime(
	uint32_t lifetime,
	MultiArenaAllocator* allocator,
	AllocatorError* err
) {}


