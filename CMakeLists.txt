cmake_minimum_required(VERSION 3.10)

project(CJitC C)

set(CMAKE_EXPORT_COMPILE_COMMANDS ON)

set(CMAKE_CONFIGURATION_TYPES
                Debug
                Release
)

set(COMMON_FLAGS -Wall -Werror)
set(DEBUG_FLAGS -g -O0)
# set(DEBUG_FLAGS -g -O0 -pg)
set(RELEASE_FLAGS -O3 -Wno-unused-but-set-variable -Wno-unused-variable)

set(CMAKE_BUILD_TYPE Debug)
# set(CMAKE_BUILD_TYPE Release)


set(CMAKE_C_STANDARD 99)
set(CMAKE_C_STANDARD_REQUIRED ON)

add_subdirectory(cjitc_lib)
add_subdirectory(cjitc_exe)
add_subdirectory(tests)
