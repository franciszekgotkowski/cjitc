package main

Token :: struct {
	tokenType: TokenType,
	kind:      TokenKind,
	lexeme:    []rune,
}

// IdentifyWord :: proc(code: rune[], words: ^Trie) -> (rune[], TokenKind, TokenType) {

// 	i: int = 0

// 	for {

// 	}

// }

Tokenise :: proc(code: []rune) -> [dynamic]Token {
	assert(code != nil)

	idx: int

	return nil
}
