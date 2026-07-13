#include <stdlib.h>

#include <range.h>
#include <allocator/allocator_errors.h>
#include <allocator/arena_allocator.h>

#include "arena_allocator_tests.h"
#include "cmocka.h"

static int32_t InitializeAllocatorAndSetupFunctions(void **state) {
    ArenaAllocatorMetadata *mem = malloc(sizeof(ArenaAllocatorMetadata));
    *mem = ArenaAllocator_Initialize();
    *state = mem;
    return 0;
}

static int32_t DeinitializeAllocator(void **state) {
    ArenaAllocator_Deinitialize(*state);
    return 0;
}

static void InitializingArenaTest(void **state) {
    ArenaAllocatorMetadata arena = ArenaAllocator_Initialize();

    assert_int_equal(arena.amountOfPageAllocations, 1);
    assert_non_null(arena.stackTop);
    assert_ptr_equal(arena.stackTop, arena.pageAllocationMetadata[0].ptr);

    for range(i, arena.pageAllocationMetadata[0].size) {
        *((char *) arena.stackTop + i) = (char) 0;
    }

    ArenaAllocator_Deinitialize(&arena);
}

static void FillWholeAllocationPageTest(void **state) {
    ArenaAllocatorMetadata *arena = *state;

    AllocatorError err;
    for range(i, DEFAULT_PAGE_ALLOCATION_SIZE) {
        err = ALLOCATOR_UNKNOWN;
        ArenaAllocator_Alloc(
            arena,
            sizeof(char),
            &err
        );
        assert_int_equal(err, ALLOCATOR_OK);
    }

    arena->stackTop = arena->pageAllocationMetadata[0].ptr;
    for range(i, DEFAULT_PAGE_ALLOCATION_SIZE/sizeof(int32_t)) {
        err = ALLOCATOR_UNKNOWN;
        ArenaAllocator_Alloc(
            arena,
            sizeof(int32_t),
            &err
        );
        assert_int_equal(err, ALLOCATOR_OK);
    }
}

static void GetManyAllocationPagesTest(void **state) {
    ArenaAllocatorMetadata *arena = *state;
    AllocatorError err;

    for range(i, DEFAULT_PAGE_ALLOCATION_SIZE*MAX_AMOUNT_OF_PAGE_ALLOCATIONS + 1) {
        err = ALLOCATOR_UNKNOWN;
        ArenaAllocator_Alloc(
            arena,
            sizeof(char),
            &err
        );
        if (i < DEFAULT_PAGE_ALLOCATION_SIZE*MAX_AMOUNT_OF_PAGE_ALLOCATIONS) {
            assert_int_equal(err, ALLOCATOR_OK);
        } else {
            assert_int_equal(err, ALLOCATOR_OUT_OF_SPACE);
            assert_int_equal(arena->amountOfPageAllocations, MAX_AMOUNT_OF_PAGE_ALLOCATIONS);
        }
    }

    ArenaAllocator_Deinitialize(arena);
    *arena = ArenaAllocator_Initialize();

    for range(i, DEFAULT_PAGE_ALLOCATION_SIZE*MAX_AMOUNT_OF_PAGE_ALLOCATIONS + 1) {
        err = ALLOCATOR_UNKNOWN;
        ArenaAllocator_Alloc(
            arena,
            sizeof(int32_t),
            &err
        );
        if (i < DEFAULT_PAGE_ALLOCATION_SIZE*MAX_AMOUNT_OF_PAGE_ALLOCATIONS/sizeof(int32_t)) {
            assert_int_equal(err, ALLOCATOR_OK);
        } else {
            assert_int_equal(err, ALLOCATOR_OUT_OF_SPACE);
            assert_int_equal(arena->amountOfPageAllocations, MAX_AMOUNT_OF_PAGE_ALLOCATIONS);
        }
    }
}

static void AlwaysAllocateNewPageTest(void **state) {
    ArenaAllocatorMetadata *arena = *state;
    AllocatorError err;

    for range(i, DEFAULT_PAGE_ALLOCATION_SIZE*MAX_AMOUNT_OF_PAGE_ALLOCATIONS + 1) {
        err = ALLOCATOR_UNKNOWN;
        ArenaAllocator_Alloc(
            arena,
            DEFAULT_PAGE_ALLOCATION_SIZE,
            &err
        );
        if (i < MAX_AMOUNT_OF_PAGE_ALLOCATIONS) {
            assert_int_equal(err, ALLOCATOR_OK);
        } else {
            assert_int_equal(err, ALLOCATOR_OUT_OF_SPACE);
            assert_int_equal(arena->amountOfPageAllocations, MAX_AMOUNT_OF_PAGE_ALLOCATIONS);
        }
    }

}

int32_t arenaAllocatorTests() {
    const struct CMUnitTest tests[] = {
        cmocka_unit_test(InitializingArenaTest),
        cmocka_unit_test_setup_teardown(
            FillWholeAllocationPageTest,
            InitializeAllocatorAndSetupFunctions,
            DeinitializeAllocator
        ),
        cmocka_unit_test_setup_teardown(
            GetManyAllocationPagesTest,
            InitializeAllocatorAndSetupFunctions,
            DeinitializeAllocator
        ),
        cmocka_unit_test_setup_teardown(
            AlwaysAllocateNewPageTest,
            InitializeAllocatorAndSetupFunctions,
            DeinitializeAllocator
        ),
    };

    return cmocka_run_group_tests_name("Arena allocator tests", tests, NULL, NULL);
}
