package main

import "core:fmt"
import "core:unicode/utf8"


TokenType :: enum u32 {
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
	// currentChar: ^byte = raw_data(s)

	code: []rune = utf8.string_to_runes(s)

	tokens: [dynamic]Token = {}


}

main :: proc() {
	code: string = "int a = 0 ; int b = 1 ; if ( a < b ) { a = 8 ; } else { b = 1 ; }"
	Tokenise(code)
	fmt.println(code, "\n")

	trie := Trie_New()

	r1 := utf8.string_to_runes("kot")
	r2 := utf8.string_to_runes("kocur")
	r3 := utf8.string_to_runes("kołmogorow")
	r4 := utf8.string_to_runes("koło")
	r5 := utf8.string_to_runes("koło biblioteki")
	r6 := utf8.string_to_runes("koło bibułki")
	r7 := utf8.string_to_runes("paweł")
	r8 := utf8.string_to_runes("pasieka")
	r9 := utf8.string_to_runes("paweł pasieka")
	err := Trie_Append(&trie, r1)
	err = Trie_Append(&trie, r2)
	err = Trie_Append(&trie, r3)
	err = Trie_Append(&trie, r4)
	err = Trie_Append(&trie, r5)
	err = Trie_Append(&trie, r6)
	err = Trie_Append(&trie, r7)
	err = Trie_Append(&trie, r8)
	err = Trie_Append(&trie, r9)

	Trie_Print(&trie)
}
