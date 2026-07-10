#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>

#include <arena_with_lifetimes_allocator.h>
#include <range.h>
#include <allocator_interface.h>

#include "arena_with_lifetimes_tests.h"
#include "allocator_errors.h"
#include "cmocka.h"

static int32_t InitializeAllocatorAndSetupFunctions(void **state) {

	setupDefaultAllocator();

	ArenaWithLifetimesAllocator *mem = malloc(sizeof(ArenaWithLifetimesAllocator));
	*mem = ArenaWithLifetimesAllocator_Initialize();
	*state = mem;
	return 0;
}

static int32_t DeinitializeAllocatorAndClerFunctions(void **state) {
	ArenaWithLifetimesAllocator_Denitialize(*state);
	clearDefaultAllocator();
	return 0;
}

static void InitializeWithoutLifetimesTest(void **state) {
	ArenaWithLifetimesAllocator alloc = ArenaWithLifetimesAllocator_Initialize();

	assert_int_equal(alloc.amountOfActiveLifetimes, 0);
	assert_int_equal(alloc.firstUnusedLifetime, 0);

	for range(i , MAX_AMOUNT_OF_ARENA_LIFETIMES) {
	assert_true(alloc.isLifetimeActive[i] == false);
}
}

static void OpenAllLifetimesTest(void **state) {
	ArenaWithLifetimesAllocator* alloc = *state;

	AllocatorError err = UNKNOWN;

	for range(i, MAX_AMOUNT_OF_ARENA_LIFETIMES) {
	int32_t lifetime = -1;
	ArenaWithLifetimesAllocator_Alloc(
		1,
		&lifetime,
		alloc,
		&err
	);
	assert_int_equal(lifetime, i);
	assert_int_equal(err, OK);
}

for range(i, MAX_AMOUNT_OF_ARENA_LIFETIMES) {
ArenaWithLifetimesAllocator_Alloc(
	1,
	&i,
	alloc,
	&err
);
assert_int_equal(err, OK);
}
}

static void OpenIncativeLifetimesTest(void **state) {
	ArenaWithLifetimesAllocator* alloc = *state;


	for range(i, MAX_AMOUNT_OF_ARENA_LIFETIMES) {
	AllocatorError err = UNKNOWN;
	int32_t lifetime = -1;
	ArenaWithLifetimesAllocator_Alloc(
		1,
		&lifetime,
		alloc,
		&err
	);
	assert_int_equal(lifetime, i);
	assert_int_equal(err, OK);
	assert_int_equal(alloc->amountOfActiveLifetimes, i+1);

	for range(j, MAX_AMOUNT_OF_ARENA_LIFETIMES) {
	ArenaWithLifetimesAllocator_Alloc(
		1,
		&j,
		alloc,
		&err
	);
	if (j <= i) {
		assert_int_equal(err, OK);
	} else {
		assert_int_equal(err, LIFETIME_IS_INACTIVE);
	}
}
}
}

static void OpenTooManyLifetimesTest(void **state) {
	ArenaWithLifetimesAllocator* alloc = *state;

	for range(i, MAX_AMOUNT_OF_ARENA_LIFETIMES * 2 ) {
		AllocatorError err = UNKNOWN;

		int32_t lifetime = -1;

		ArenaWithLifetimesAllocator_Alloc(
			1,
			&lifetime,
			alloc,
			&err
		);

		if (i < MAX_AMOUNT_OF_ARENA_LIFETIMES) {
			assert_int_equal(err, OK);
		} else {
			assert_int_equal(err, OUT_OF_LIFETIMES);
		}

	}
}

int32_t arenaWithLifetimesAllocatorTests() {
	const struct CMUnitTest tests[] = {
		cmocka_unit_test(InitializeWithoutLifetimesTest),
		cmocka_unit_test_setup_teardown(
			OpenAllLifetimesTest,
			InitializeAllocatorAndSetupFunctions,
			DeinitializeAllocatorAndClerFunctions
		),
		cmocka_unit_test_setup_teardown(
			OpenIncativeLifetimesTest,
			InitializeAllocatorAndSetupFunctions,
			DeinitializeAllocatorAndClerFunctions
		),
		cmocka_unit_test_setup_teardown(
			OpenTooManyLifetimesTest,
			InitializeAllocatorAndSetupFunctions,
			DeinitializeAllocatorAndClerFunctions
		)
	};

	return cmocka_run_group_tests_name("Arena with lifetimes allocator tests", tests, NULL, NULL);
}
