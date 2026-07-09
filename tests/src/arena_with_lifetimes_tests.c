#include <arena_with_lifetimes_tests.h>

#include <cjitc_lib/arena_with_lifetimes_allocator.h>
#include <stdlib.h>
#include <cjitc_lib/range.h>

#include <cmocka.h>

static int32_t InitializeArena(void **state) {
    ArenaWithLifetimesAllocator *mem = malloc(sizeof(ArenaWithLifetimesAllocator));
    *mem = ArenaWithLifetimesAllocator_Initialize();
    *state = mem;
    return 0;
}

static int32_t DeinitializeArena(void **state) {
    ArenaWithLifetimesAllocator_Denitialize(*state);
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

int32_t arenaWithLifetimesAllocatorTests() {
    const struct CMUnitTest tests[] = {
        cmocka_unit_test(InitializeWithoutLifetimesTest),
        // cmocka_unit_test_setup_teardown(
        //     ,
        //     InitializeArena,
        //     DeinitializeArena
        // ),
    };

    return cmocka_run_group_tests_name("Arena with lifetimes allocator tests", tests, NULL, NULL);
}
