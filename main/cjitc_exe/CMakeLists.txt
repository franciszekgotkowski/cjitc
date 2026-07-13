add_executable(cjitc_exe)

target_compile_options(cjitc_exe PRIVATE
				${COMMON_FLAGS}
				$<$<CONFIG:Debug>:${DEBUG_FLAGS}>
				$<$<CONFIG:Release>:${RELEASE_FLAGS}>
)

target_sources(cjitc_exe PRIVATE
				src/main.c
)

target_include_directories(cjitc_exe PRIVATE
								${CMAKE_CURRENT_SOURCE_DIR}/headers
								${CMAKE_SOURCE_DIR}/cjitc_lib/headers/export
								# ${CMAKE_HOME_DIR}
)

target_link_directories(cjitc_exe PRIVATE
								# ${CMAKE_CURRENT_SOURCE_DIR}/libs/dynamic
)


target_link_libraries(cjitc_exe PRIVATE
				cjitc
)

