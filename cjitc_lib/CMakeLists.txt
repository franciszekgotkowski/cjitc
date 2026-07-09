add_library(cjitc STATIC)

target_compile_options(cjitc PRIVATE
    ${COMMON_FLAGS}
    $<$<CONFIG:Debug>:${DEBUG_FLAGS}>
    $<$<CONFIG:Release>:${RELEASE_FLAGS}>
)

target_sources(cjitc PRIVATE
    src/main.c
    src/allocator_interface.c src/arena_allocator.c
    src/arena_with_lifetimes_allocator.c
    src/platform/memory_linux.c
    #src/heap_with_lifetimes_allocator.c

    headers/export/cjitc_lib/arena_allocator.h
    headers/export/cjitc_lib/arena_with_lifetimes_allocator.h
)

target_include_directories(cjitc PRIVATE
        ${CMAKE_CURRENT_SOURCE_DIR}/headers/export/cjitc_lib
        ${CMAKE_CURRENT_SOURCE_DIR}/headers/internal
)

target_link_directories(cjitc PRIVATE
        # ${CMAKE_CURRENT_SOURCE_DIR}/libs/dynamic
)

target_link_libraries(cjitc PRIVATE
)

