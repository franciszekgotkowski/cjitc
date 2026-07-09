#include <arena_allocator_tests.h>
#include <libs/cmocka.h>
#include <stdio.h>
#include <stdlib.h>
#include <cjitc_lib/arena_allocator.h>

static void t1(void **state) {
	assert_int_equal(1, 1);
	assert_int_equal(1, 2);
}

static void t2(void **state) {
	ArenaAllocatorMetadata* arena = *state;
	assert_non_null(arena);
}

static int32_t InitializeArena(void** state) {
	ArenaAllocatorMetadata* mem = malloc(sizeof(ArenaAllocatorMetadata));
	*mem = ArenaAllocator_Initialize();
	*state = mem;
	return 0;
}

static int32_t DeinitializeArena(void** state) {
	ArenaAllocator_Deinitialize(*state);
	return 0;
}

int32_t arenaAllocatorTests() {
	const struct CMUnitTest tests[]= {
		cmocka_unit_test(t1),
		cmocka_unit_test_setup_teardown(
			t2,
			InitializeArena,
			DeinitializeArena
		)
	};

	return cmocka_run_group_tests_name("Arena allocator tests", tests, NULL, NULL);
}
