#include <memoryapi.h>
#include <stddef.h>
#include <windows.h>
#include <stdio.h>

#include <memory_allocations.h>
#include <assert.h>

// inline void* mem_alloc(u64 size) {
inline void* mem_alloc_on_address(size_t size, void* address) {
    // if (size % (4*KB) != 0 || size < 4*KB) {
    //     printf("extending size to fill entire page\n");
    //     u64 oldsize = size;
    //     size /= 4*KB;
    //     size *= 4*KB;
    //     size += 4*KB;
    //     printf("mapping %llu instead of %llu\n", size, oldsize);
    // }
    // void* ptr = mmap(NULL, size, PROT_READ | PROT_WRITE, MAP_PRIVATE | MAP_ANONYMOUS, -1, 0);
    void* ptr = VirtualAlloc(
            address,                       // Let OS choose address
            size,                       // Size in bytes
            MEM_RESERVE | MEM_COMMIT,   // Reserve + commit
            PAGE_READWRITE);             // Read/write access

    assert(ptr == address);
    if (ptr != address) {
  		printf("memory allocation failed!\n");
   		return NULL;
    }

    return ptr;
}

inline void* mem_alloc(size_t size) {
    // if (size % (4*KB) != 0 || size < 4*KB) {
    //     printf("extending size to fill entire page\n");
    //     u64 oldsize = size;
    //     size /= 4*KB;
    //     size *= 4*KB;
    //     size += 4*KB;
    //     printf("mapping %llu instead of %llu\n", size, oldsize);
    // }
    // void* ptr = mmap(NULL, size, PROT_READ | PROT_WRITE, MAP_PRIVATE | MAP_ANONYMOUS, -1, 0);
    void* ptr = VirtualAlloc(
            NULL,                       // Let OS choose address
            size,                       // Size in bytes
            MEM_RESERVE | MEM_COMMIT,   // Reserve + commit
            PAGE_READWRITE);             // Read/write access

    assert(ptr != NULL);
    if (ptr == NULL) {
   		printf("memory allocation failed!\n");
   		return NULL;
    }

    return ptr;
}

inline void mem_dealloc(void* ptr, size_t size) {
    assert(ptr != NULL);
    VirtualFree(ptr, 0, size);
}

