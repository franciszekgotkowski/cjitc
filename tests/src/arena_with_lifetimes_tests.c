#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>

#include <range.h>
#include <allocator_interface.h>

#include "arena_with_lifetimes_tests.h"
#include "allocator_errors.h"
#include "cmocka.h"

void (*SetupFunction)() = &setupDefaultAllocator;

static int32_t InitializeAllocatorAndSetupFunctions(void **state) {

	SetupFunction();

	ArenaWithLifetimesAllocator *mem = malloc(sizeof(ArenaWithLifetimesAllocator));
	*mem = InitializeAllocator();
	*state = mem;
	return 0;
}

static int32_t DeinitializeAllocatorAndClerFunctions(void **state) {
	DeinitializeAllocator(*state);
	clearAllocatorFunctions();
	return 0;
}

static void InitializeWithoutLifetimesTest(void **state) {
	SetupFunction();
	ArenaWithLifetimesAllocator alloc = InitializeAllocator();

	assert_int_equal(AmountOfActiveLifetimes(&alloc), 0);
	assert_int_equal(FirstUnusedLifetime(&alloc), 0);

	for range(i , MAX_AMOUNT_OF_ARENA_LIFETIMES) {
	assert_true(IsLifetimeActive(&alloc, i) == false);
}
}

static void OpenAllLifetimesTest(void **state) {
	ArenaWithLifetimesAllocator* alloc = *state;

	AllocatorError err = UNKNOWN;

	for range(i, MAX_AMOUNT_OF_ARENA_LIFETIMES) {
	int32_t lifetime = -1;
	Alloc(
		1,
		&lifetime,
		alloc,
		&err
	);
	assert_int_equal(lifetime, i);
	assert_int_equal(err, OK);
}

for range(i, MAX_AMOUNT_OF_ARENA_LIFETIMES) {
Alloc(
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
	Alloc(
		1,
		&lifetime,
		alloc,
		&err
	);
	assert_int_equal(lifetime, i);
	assert_int_equal(err, OK);
	assert_int_equal(AmountOfActiveLifetimes(alloc), i+1);

	for range(j, MAX_AMOUNT_OF_ARENA_LIFETIMES) {
	Alloc(
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

		Alloc(
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

static void OpenAndDeleteLifetimesTest(void **state) {
	ArenaWithLifetimesAllocator* alloc = *state;

	for range(i, MAX_AMOUNT_OF_ARENA_LIFETIMES ) {
		AllocatorError err = UNKNOWN;

		int32_t lifetime = -1;

		assert_int_equal(AmountOfActiveLifetimes(alloc), i);
		Alloc(
			1,
			&lifetime,
			alloc,
			&err
		);
		assert_int_equal(err, OK);
		assert_int_equal(lifetime, i);
		assert_int_equal(AmountOfActiveLifetimes(alloc), i+1);
		DeallocLifetime(
			i,
			alloc,
			&err
		);
		assert_int_equal(AmountOfActiveLifetimes(alloc), i);
		assert_int_equal(err, OK);
		lifetime = -1;
		Alloc(
			1,
			&lifetime,
			alloc,
			&err
		);
		assert_int_equal(AmountOfActiveLifetimes(alloc), i+1);
		assert_int_equal(err, OK);
		assert_int_equal(lifetime, i);

	}
	assert_int_equal(AmountOfActiveLifetimes(alloc), MAX_AMOUNT_OF_PAGE_ALLOCATIONS);
}

static void DeleteInactiveLifetimesTest(void **state) {
	ArenaWithLifetimesAllocator* alloc = *state;

	AllocatorError err = UNKNOWN;
	for range(i, MAX_AMOUNT_OF_ARENA_LIFETIMES ) {
		assert_int_equal(
			AmountOfActiveLifetimes(
				alloc
			),
			0
		);
		DeallocLifetime(
			i,
			alloc,
			&err
		);
		assert_int_equal(err, LIFETIME_IS_INACTIVE);
		assert_int_equal(
			AmountOfActiveLifetimes(
				alloc
			),
			0
		);
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
		),
		cmocka_unit_test_setup_teardown(
			OpenAndDeleteLifetimesTest,
			InitializeAllocatorAndSetupFunctions,
			DeinitializeAllocatorAndClerFunctions
		),
		cmocka_unit_test_setup_teardown(
			DeleteInactiveLifetimesTest,
			InitializeAllocatorAndSetupFunctions,
			DeinitializeAllocatorAndClerFunctions
		)
	};

	return cmocka_run_group_tests_name("Arena with lifetimes allocator tests", tests, NULL, NULL);
}
