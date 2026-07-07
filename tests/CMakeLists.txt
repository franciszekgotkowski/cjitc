add_executable(tests)

target_sources(tests PRIVATE
	src/main.c
)

target_compile_options(tests PRIVATE
	$<$<CONFIG:Debug>:${DEBUG_FLAGS}>
	$<$<CONFIG:Release>:${RELEASE_FLAGS}>
)


target_include_directories(tests PRIVATE
	${CMAKE_CURRENT_SOURCE_DIR}/headers
)

# target_link_directories(tests PRIVATE
# 		${CMAKE_HOME_DIRECTORY}/libs/dynamic
# )

add_subdirectory(cmocka)

target_link_libraries(tests PRIVATE
	cmocka
)



