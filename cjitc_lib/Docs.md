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
