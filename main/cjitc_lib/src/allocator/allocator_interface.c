#include "allocator_interface.h"
#include "arena_with_lifetimes_allocator.h"
#include <assert.h>

PrototypeInitializeAllocator *ptr_InitializeAllocator = NULL;
PrototypeDeinitializeAllocator *ptr_DeinitializeAllocator = NULL;
PrototypeAlloc *ptr_Alloc = NULL;
PrototypeDeallocLifetime *ptr_DeallocLifetime = NULL;
PrototypeIsLifetimeActive* ptr_IsLifetimeActive = NULL;
PrototypeAmountOfActiveLifetimes* ptr_AmountOfActiveLifetimes = NULL;
PrototypeFirstUnusedLifetime* ptr_FirstUnusedLifetime = NULL;

void setupAllocatorFunctions(
    PrototypeInitializeAllocator *InitializeAllocator,
    PrototypeDeinitializeAllocator *DeinitializeAllocator,
    PrototypeAlloc *Alloc,
    PrototypeDeallocLifetime *DeallocLifetime,
    PrototypeIsLifetimeActive* IsLifetimeActive,
    PrototypeAmountOfActiveLifetimes* AmountOfActiveLifetimes,
    PrototypeFirstUnusedLifetime* FirstUnusedLifetime
) {
    assert(InitializeAllocator);
    assert(DeinitializeAllocator);
    assert(InitializeAllocator);
    assert(DeallocLifetime);
    assert(IsLifetimeActive);
    assert(AmountOfActiveLifetimes);
    assert(FirstUnusedLifetime);

    ptr_InitializeAllocator = InitializeAllocator;
    ptr_DeinitializeAllocator = DeinitializeAllocator;
    ptr_Alloc = Alloc;
    ptr_DeallocLifetime = DeallocLifetime;
    ptr_IsLifetimeActive = IsLifetimeActive;
    ptr_AmountOfActiveLifetimes = AmountOfActiveLifetimes;
    ptr_FirstUnusedLifetime = FirstUnusedLifetime;
}

void clearAllocatorFunctions(
) {
    ptr_InitializeAllocator = NULL;
    ptr_DeinitializeAllocator = NULL;
    ptr_Alloc = NULL;
    ptr_DeallocLifetime = NULL;
    ptr_IsLifetimeActive = NULL;
    ptr_AmountOfActiveLifetimes = NULL;
    ptr_FirstUnusedLifetime = NULL;
}

void setupDefaultAllocator() {
    setupAllocatorFunctions(
        &ArenaWithLifetimesAllocator_Initialize,
        &ArenaWithLifetimesAllocator_Denitialize,
        &ArenaWithLifetimesAllocator_Alloc,
        &ArenaWithLifetimesAllocator_DeallocLifetime,
        &ArenaWithLifetimesAllocator_isLifetimeActive,
        &ArenaWithLifetimesAllocator_amountOfActiveLifetimes,
        &ArenaWithLifetimesAllocator_firstUnusedLifetime
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
    int32_t lifetime,
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

bool IsLifetimeActive(
	ArenaWithLifetimesAllocator* allocator,
	int32_t lifetime
) {
	assert(ptr_IsLifetimeActive);
	assert(allocator);

	return ptr_IsLifetimeActive(
		allocator,
		lifetime
	);
}

int32_t AmountOfActiveLifetimes(
	ArenaWithLifetimesAllocator* allocator
) {
	assert(ptr_AmountOfActiveLifetimes);
	assert(allocator);

	return ptr_AmountOfActiveLifetimes(
		allocator
	);
}

int32_t FirstUnusedLifetime(
	ArenaWithLifetimesAllocator* allocator
) {
	assert(ptr_FirstUnusedLifetime);
	assert(allocator);

	return ptr_FirstUnusedLifetime(
		allocator
	);
}
