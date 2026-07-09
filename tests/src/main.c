#include <stdio.h>
#include <stdint.h>

#include <arena_allocator_tests.h>

int main(void) {
	int32_t success = 0;

    success += arenaAllocatorTests();

    if (success == 0) {
    	printf("\033[32m\n0================================0\n");
    	printf("All tests passed!");
    	printf("\n0================================0\n\033[0m");
    } else {
    	printf("\033[31m\n0================================0\n");
   		printf("%d test groups did not pass!", success);
    	printf("\n0================================0\n\033[0m");
    }

    return success;
}
