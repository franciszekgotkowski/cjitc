add_executable(tests
src/arena_with_lifetimes_tests.c)

target_sources(tests PRIVATE
src/main.c
src/arena_allocator_tests.c
)

target_compile_options(tests PRIVATE
$<$<CONFIG:Debug>:${DEBUG_FLAGS}>
$<$<CONFIG:Release>:${RELEASE_FLAGS}>
)


target_include_directories(tests PUBLIC
${CMAKE_SOURCE_DIR}/cjitc_lib/src
${CMAKE_SOURCE_DIR}/cjitc_exe/src
${CMAKE_CURRENT_SOURCE_DIR}/src
)

# target_link_directories(tests PRIVATE
# 		${CMAKE_HOME_DIRECTORY}/libs/dynamic
# )

add_subdirectory(cmocka)

target_link_libraries(tests PRIVATE
cmocka
cjitc
)



