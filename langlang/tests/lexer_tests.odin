package main

import lang "../src"
import "core:fmt"
import "core:testing"
import "core:unicode/utf8"

exp :: testing.expect

setupTestArrays :: proc() -> [dynamic][]rune {
	tests := []string {
		`declare x int;`,
		`declare f function;`,
		`x = 11;`,
		`x = 1.2;`,
		`x = a + b;`,
		`x = a - b;`,
		`x = "hello world";`,
		`x = 'a';`,
		`x = f;`,
		`x = f(a, b);`,
		`return x;`,
		`if a < b { return a; }`,
		`if a > b { return b; }`,
		`if a <= b { x = a + 1; }`,
		`if a >= b { x = b - 1; }`,
		`if a == b { return a; }`,
		`
		declare x int;
		declare y int;

		x = 11;
		y = 25;
		x = x + y;

		if x >= y {
		return x;
		}
		`,
		`
		declare message int;
		declare character int;
		declare number int;

		message = "hello parser";
		character = 'x';
		number = 12.75;

		if number == 12.75 {
		return message;
		}
		`,
		`
		if a<b {}
		if a<=b {}
		if a>b {}
		if a>=b {}
		if a==b {}
		a=b;
		a=a+b;
		a=a-b;
		`,
	}
	test_runes: [dynamic][]rune = {}

	for i in 0 ..< len(tests) {
		append(&test_runes, utf8.string_to_runes(tests[i]))
	}

	return test_runes
}

tokenDynamicArrayAndSliceMatch :: proc(a: [dynamic]lang.Token, b: []lang.Token) -> bool {

	if len(a) != len(b) do return false

	for i in 0 ..< len(a) {
		if a[i].type != b[i].type do return false
		if a[i].type != .LITERAL && a[i].type != .IDENTIFIER {
			if a[i].kind != b[i].kind do return false
		} else {
			if len(a[i].lexeme) != len(b[i].lexeme) do return false
			for j in 0 ..< len(a[i].lexeme) {
				if a[j].lexeme[j] != b[j].lexeme[j] do return false
			}
		}
	}

	return true
}

tokensMatch :: proc(a, b: lang.Token) -> bool {
	if a.type != b.type do return false
	if a.type != .LITERAL && a.type != .IDENTIFIER {
		if a.kind != b.kind do return false
	} else {
		if len(a.lexeme) != len(b.lexeme) do return false
		for j in 0 ..< len(a.lexeme) {
			if a.lexeme[j] != b.lexeme[j] do return false
		}
	}
	return true
}

tokenDynamicArraysMatch :: proc(a, b: [dynamic]lang.Token) -> bool {

	if len(a) != len(b) do return false

	for i in 0 ..< len(a) {
		if !tokensMatch(a[i], b[i]) do return false
	}

	return true
}

tokenArrMatch :: proc {
	tokenDynamicArrayAndSliceMatch,
	tokenDynamicArraysMatch,
}

endTest :: proc(code: [dynamic][]rune) {
	for _, i in code {
		delete(code)
	}
	delete(code)
}

@(test)
IdentifyWord_test :: proc(t: ^testing.T) {
	trie := Prepare_Trie()
	defer lang.Trie_Delete(&trie)

	tokens: []lang.Token = {
		lang.Token{type = .KEYWORD, kind = lang.Keyword.DECLARE},
		lang.Token{type = .IDENTIFIER, lexeme = []rune{'x'}},
		lang.Token{type = .KEYWORD, kind = lang.Keyword.INT},
		lang.Token{type = .DELIMITER, kind = lang.Delimiter.SEMICOLUMN},
	}

	runes := utf8.string_to_runes(`declare x int;`)
	defer delete(runes)
	code := runes

	r, type, kind := lang.IdentifyWord(code, &trie)
	token := lang.Token {
		type   = type,
		kind   = kind,
		lexeme = r,
	}
	exp(t, tokensMatch(token, tokens[0]))
	code = code[8:]
	r, type, kind = lang.IdentifyWord(code, &trie)
	token = lang.Token {
		type   = type,
		kind   = kind,
		lexeme = r,
	}
	exp(t, r == nil)
	code = code[2:]
	r, type, kind = lang.IdentifyWord(code, &trie)
	token = lang.Token {
		type   = type,
		kind   = kind,
		lexeme = r,
	}
	exp(t, tokensMatch(token, tokens[2]))
	code = code[3:]
	r, type, kind = lang.IdentifyWord(code, &trie)
	token = lang.Token {
		type   = type,
		kind   = kind,
		lexeme = r,
	}
	exp(t, tokensMatch(token, tokens[3]))


}
