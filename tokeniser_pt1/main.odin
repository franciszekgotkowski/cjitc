package main

import "core:encoding/json"
import "core:fmt"
import "core:slice"
import "core:unicode/utf8"

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
}

Token :: struct {
	type:    TokenType `json:"type"`,
	keyword: Keyword `json:"Keyword"`,
	lexeme:  []rune `json:"lexeme"`,
	id:      int `json:"id"`,
}

Tokenise :: proc(code: []rune, trie: ^Trie) -> [dynamic]Token {

	tokens: [dynamic]Token = {}
	tip: int = 0

	tokenise_step :: proc(
		code: []rune,
		node: ^TrieNode,
		trie: ^Trie,
		tip: ^int,
		length: u32,
	) -> (
		int,
		Keyword,
		[]rune,
	) {
		assert(code != nil)
		assert(len(code) > 0)
		assert(node != nil)
		assert(trie != nil)
		assert(tip != nil)


		lexeme: []rune


		if node.isWord {
			return int(length + 1), node.keyword, nil
		} else {
			if len(code) == 1 {
				if length != 0 {
					return -1, Keyword(-1), nil
				} else {
					for v, i in node.children {
						if v.value == code[0] {
							tip^ += 1
							return 1, v.keyword, code[:]
						}
					}
					return -1, Keyword(-1), nil
				}
			}
		}

		lexemeLen: int
		keyword: Keyword
		for v, i in node.children {
			if v.value == code[0] {
				tip^ += 1
				lexemeLen, keyword, _ = tokenise_step(
					code[1:],
					&node.children[i],
					trie,
					tip,
					length + 1,
				)
				if lexemeLen != -1 {
					if &trie.root == node {
						lexemeLen -= 1
						lexeme = code[:lexemeLen]
						return lexemeLen, keyword, lexeme
					} else {
						return lexemeLen, keyword, nil
					}
				}
			}
		}


		return -1, Keyword(-1), nil
	}

	for tip < len(code) {
		cutcode := code[tip:]
		lenght, keyword, r := tokenise_step(cutcode, &trie.root, trie, &tip, 0)
		if lenght != -1 {
			append(
				&tokens,
				Token{type = .KEYWORD, keyword = keyword, lexeme = r, id = len(tokens)},
			)
		} else {
			tip += 1

			if cutcode[0] != ' ' {

			}
		}
	}

	return tokens
}

main :: proc() {
	code: string = "int a = 0 ; int b = 1 ; if ( a < b ) { a = 8 ; } else { b = 1 ; }"
	fmt.println(code, "\n")

	trie := Trie_New()

	keys: []string = slice.enumerated_array(&keywords)
	err := Trie_AppendAll(&trie, keys)
	assert(err == .OK)

	Trie_Print(&trie)

	// c := ";;i;nintt(if ;"

	// tokens := Tokenise(utf8.string_to_runes(c), &trie)
	// fmt.printfln("\namount of tokens: %v", len(tokens))
	// for i in 0 ..< len(tokens) {
	// 	fmt.printf("token: \"%s\", keyword: %v\n", tokens[i].lexeme, tokens[i].keyword)
	// }

	tokens := Tokenise(utf8.string_to_runes(code), &trie)
	fmt.printfln("\namount of tokens: %v", len(tokens))
	for i in 0 ..< len(tokens) {
		fmt.printf("token: \"%s\", keyword: %v\n", tokens[i].lexeme, tokens[i].keyword)
	}

	js, _ := json.marshal(tokens, {pretty = true, use_enum_names = true})
	fmt.printfln("%s\n", js)
}
