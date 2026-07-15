package main

import "core:fmt"
import "core:slice"

TokenType :: enum u32 {
	KEYWORD,
	UNKNOWN,
}

Keyword :: enum i32 {
	INT,
	EQUAL,
	SMALLER,
	LARGER,
	PLUS,
	MINUS,
	SEMICOLUMN,
	IF,
	ELSE,
	BRACE_OPEN,
	BRACE_CLOSE,
	CURLY_BRACE_OPEN,
	CURLY_BRACE_CLOSE,
	// DIGIT_0,
	// DIGIT_1,
	// DIGIT_2,
	// DIGIT_3,
	// DIGIT_4,
	// DIGIT_5,
	// DIGIT_6,
	// DIGIT_7,
	// DIGIT_8,
	// DIGIT_9,
}

keywords: [Keyword]string = {
	.INT               = "int",
	.EQUAL             = "=",
	.SMALLER           = "<",
	.LARGER            = ">",
	.PLUS              = "+",
	.MINUS             = "-",
	.SEMICOLUMN        = ";",
	.IF                = "if",
	.ELSE              = "else",
	.BRACE_OPEN        = "(",
	.BRACE_CLOSE       = ")",
	.CURLY_BRACE_OPEN  = "{",
	.CURLY_BRACE_CLOSE = "}",
	// .DIGIT_0           = "0",
	// .DIGIT_1           = "1",
	// .DIGIT_2           = "2",
	// .DIGIT_3           = "3",
	// .DIGIT_4           = "4",
	// .DIGIT_5           = "5",
	// .DIGIT_6           = "6",
	// .DIGIT_7           = "7",
	// .DIGIT_8           = "8",
	// .DIGIT_9           = "9",
}

Token :: struct {
	type:    TokenType,
	keyword: Keyword,
	lexeme:  []rune,
	id:      u32,
}

// TokeniseRunes :: proc(code: []rune, keywords: ^Trie, keyword: Keyword) -> [dynamic]Token {
// 	assert(code != nil)
// 	tokens: [dynamic]Token = {}
// 	defer delete(tokens)

// 	lexeme: [dynamic]rune
// 	defer delete(lexeme)

// 	tip: ^TrieNode = &keywords.root
// 	i := 0
// 	for i < len(code) {
// 		exists, idx := TrieNode_ChildExists(tip, code[i])
// 		if exists {
// 			tip = &tip.children[idx]
// 			append(&lexeme, code[i])
// 			if tip.isWord {
// 				t: Token = {
// 					type =
// 				}
// 				append(&tokens, )
// 			}
// 		}
// 	}

// 	return tokens
// }

// TokeniseString :: proc(str: string, keywords: ^Trie, keyword: Keyword) -> [dynamic]Token {
// 	assert(keywords != nil)
// 	return TokeniseRunes(utf8.string_to_runes(str), keywords, keyword)
// }

// Tokenise :: proc {
// 	TokeniseRunes,
// 	TokeniseString,
// }

main :: proc() {
	code: string = "int a = 0 ; int b = 1 ; if ( a < b ) { a = 8 ; } else { b = 1 ; }"
	fmt.println(code, "\n")

	trie := Trie_New()

	keys: []string = slice.enumerated_array(&keywords)
	err := Trie_AppendAll(&trie, keys)
	assert(err == .OK)

	// Tokenise(code, &trie)

	Trie_Print(&trie)
}
