package main

import "core:fmt"
import "core:mem"

code: string = "int a = 0 ; int b = 1 ; if ( a < b ) { a = 8 ; } else { b = 1 ; }"

TokenType :: enum {
	INT,
	VARNAME,
	EQUAL,
	SMALLER,
	LARGER,
	DIGIT,
	SEMICOLUMN,
	IF,
	ELSE,
	BRACE_OPEN,
	BRACE_CLOSE,
	CURLY_BRACE_OPEN,
	CURLY_BRACE_CLOSE,
}

Token :: struct {
	type:   TokenType,
	lexeme: []rune,
	id:     u32,
}

Tokenise :: proc(s: string) {
	currentChar: ^byte = raw_data(s)

	for i in 0 ..< len(s) {
		fmt.printf("%c ", currentChar^)
		currentChar = mem.ptr_offset(currentChar, size_of(byte))
	}
}

main :: proc() {
	Tokenise(code)
}
