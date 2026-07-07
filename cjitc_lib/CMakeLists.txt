add_library(cjitc STATIC )

target_compile_options(cjitc PRIVATE
    ${COMMON_FLAGS}
    $<$<CONFIG:Debug>:${DEBUG_FLAGS}>
    $<$<CONFIG:Release>:${RELEASE_FLAGS}>
)

target_sources(cjitc PRIVATE
    src/main.c
)

target_include_directories(cjitc PRIVATE
        ${CMAKE_CURRENT_SOURCE_DIR}/headers
)

target_link_directories(cjitc PRIVATE
        # ${CMAKE_CURRENT_SOURCE_DIR}/libs/dynamic
)

target_link_libraries(cjitc PRIVATE
)

