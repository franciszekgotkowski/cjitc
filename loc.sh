#!/bin/bash

# Define the directories to search
TARGET_DIRS=(
  "cjitc_lib/headers"
  "cjitc_lib/src"
  "cjitc_exe/headers"
  "cjitc_exe/src"
  "tests/src"
)

# Use find to locate .c and .h files and pass them to wc -l
find "${TARGET_DIRS[@]}" -type f \( -name "*.c" -o -name "*.h" -o -name "*.vert" -o -name "*.frag" \) -exec wc -l {} +
