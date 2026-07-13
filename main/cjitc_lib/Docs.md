## High level architecture
lexer -> parser/syntax analizer -> semantic analizer -> IR gen -> CodeGen


#### Preprocessor Preprocessor will change the file before it gets compiled. It will resolve macros etc.
#### Lexer
Lexer transforms input file (string) into an array of tokens

#### Parser/Syntax analizer
Parser will do syntax analysis. It will check if operators have their required operands

#### Semantic analizer
Semantic analizer will check if operators have their required operand types and fix the code if needed and possible. For example it will change int to float when multiplying float with int

#### IR gen
Generating generic intermediate code that will be then easily translatable to real code.
If i will decide to write new frontend to new language i will still be able to generate IR and output to any backend that accepts this IR

#### CodeGen
Code generation from IR. CodeGen will have multiple backends - first asm and then native object files and callable memory






## Key features
1. Custom allocator injections - User will be able to provide their custom allocator for the compiler. This way compiler will give more controll to the user.
2. Multiple backends - Compiler will be able to emit linux and windows object files as well as creating runnable code in runtime and pulling function by sygnatures from it.
3. No shared dependencies besides libc
4. cjitc will have library and executable interface


### Custom allocators
User provided allocators need to follow interface provided in allocator_interface.h

Before using library, custom allocator should be setup with  setupAllocatorFunctions() function and by typedefing cjitc_allocator. Functions can also be cleared with clearAllocatorFunctions() function.

cjitc provides default allocator - multiarena or arena with lifetimes allocator (it manages multiple arenas which are lifetimes in this case). It can be setup with setupDefaultAllocator() function.

#### Testing your allocator
Custom allocators can be tested!

arena_with_lifetimes_tests.c file contains test suite for the default allocator, but it is trivially easy to inject other allocators. Just change SetupFunction pointer to your setupAllocator function and tests will run with your allocator