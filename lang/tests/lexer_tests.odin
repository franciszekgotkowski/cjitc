package tests

import lang "../src"
import "core:encoding/json"
import "core:fmt"
import "core:testing"
import "core:unicode/utf8"

@(private = "file")
Trie :: lang.Trie(lang.RuneWithToken)
@(private = "file")
Node :: lang.TrieNode(lang.RuneWithToken)
RuneWithToken :: lang.RuneWithToken

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

	if len(a) != len(b) {
		return false
	}

	for i in 0 ..< len(a) {
		if !lang.Token_Match(a[i], b[i]) do return false
	}

	return true
}

tokenDynamicArraysMatch :: proc(a, b: [dynamic]lang.Token) -> bool {

	if len(a) != len(b) do return false

	for i in 0 ..< len(a) {
		if !lang.Token_Match(a[i], b[i]) do return false
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
	// trie := Prepare_Trie()
	trie := lang.make_token_trie()
	defer lang.Trie_Delete(RuneWithToken, &trie)

	tokens: []lang.Token = {
		lang.Token{type = .KEYWORD, kind = lang.Keyword.DECLARE},
		lang.Token{type = .IDENTIFIER, lexeme = []rune{'x'}},
		lang.Token{type = .KEYWORD, kind = lang.Keyword.INT},
		lang.Token{type = .DELIMITER, kind = lang.Delimiter.SEMICOLUMN},
	}

	runes := utf8.string_to_runes(`declare x int;`)
	defer delete(runes)
	code := runes

	token := lang.IdentifyWord(code, &trie)
	exp(t, lang.Token_Match(token, tokens[0]))
	code = code[8:]
	token = lang.IdentifyWord(code, &trie)
	exp(t, token.lexeme == nil)
	code = code[2:]
	token = lang.IdentifyWord(code, &trie)
	exp(t, lang.Token_Match(token, tokens[2]))
	code = code[3:]
	token = lang.IdentifyWord(code, &trie)
	exp(t, lang.Token_Match(token, tokens[3]))

}

@(test)
IdentifyLiteral_test :: proc(t: ^testing.T) {
	trie := lang.make_token_trie()
	defer lang.Trie_Delete(RuneWithToken, &trie)

	str: []string = {"000", "13", "sdf", " ", "\t", "\"", "\"\"", "\"sdf\"", "'sdf'", "'"}
	errs: []lang.LexerError = {
		.OK,
		.OK,
		.NOT_A_LITERAL,
		.NOT_A_LITERAL,
		.NOT_A_LITERAL,
		.NOT_A_TOKEN,
		.OK,
		.OK,
		.OK,
		.NOT_A_TOKEN,
	}
	literals: []lang.Literal = {
		.DECIMAL,
		.DECIMAL,
		.DECIMAL,
		.DECIMAL,
		.DECIMAL,
		.DECIMAL,
		.TEXT,
		.TEXT,
		.CHARACTER,
		.CHARACTER,
	}
	runes: [dynamic][]rune
	defer {
		for _, i in runes {
			delete(runes[i])
		}
		delete(runes)
	}

	for v, _ in str {
		append(&runes, utf8.string_to_runes(v))
	}

	for v, i in runes {
		token, err := lang.IdentifyLiteral(v)
		exp(t, err == errs[i])
		if err == .OK {
			exp(t, token.kind == literals[i])
		}
	}

}

@(test)
CreateIdentifier_test :: proc(t: ^testing.T) {
	str: []string = {
		"_",
		"__",
		"_sd_",
		"0",
		"_0",
		"}",
		"sdf",
		"func",
		"function",
		"return",
		"returnn",
		"0",
		"|",
		"\"",
	}
	lengths: []int = {1, 2, 4, 0, 2, 0, 3, 4, 0, 0, 7, 0, 0, 0}

	trie := lang.make_token_trie()
	defer lang.Trie_Delete(RuneWithToken, &trie)

	runes: [dynamic][]rune
	defer {
		for _, i in runes {
			delete(runes[i])
		}
		delete(runes)
	}
	for v, i in str {
		append(&runes, utf8.string_to_runes(v))
	}

	for v, i in runes {
		id := lang.CreateIdentifier(v, &trie)

		if len(id.lexeme) != lengths[i] {
			exp(t, len(id.lexeme) == lengths[i])
		}
	}
}


@(test)
Tokenise_test :: proc(t: ^testing.T) {
	runes := setupTestArrays()
	defer {
		for _, i in runes {
			delete(runes[i])
		}
		delete(runes)
	}

	trie := lang.make_token_trie()
	defer lang.Trie_Delete(RuneWithToken, &trie)

	// "declare x int;"
	tokenArrays: [][]lang.Token = {
		{
			lang.Token{type = .KEYWORD, kind = lang.Keyword.DECLARE, lexeme = nil},
			lang.Token{type = .IDENTIFIER, kind = lang.Literal.DECIMAL, lexeme = []rune{'x'}},
			lang.Token{type = .KEYWORD, kind = lang.Keyword.INT, lexeme = nil},
			lang.Token{type = .DELIMITER, kind = lang.Delimiter.SEMICOLUMN, lexeme = nil},
		},
		{
			lang.Token{type = .KEYWORD, kind = lang.Keyword.DECLARE, lexeme = nil},
			lang.Token{type = .IDENTIFIER, kind = lang.Literal.DECIMAL, lexeme = []rune{'f'}},
			lang.Token{type = .KEYWORD, kind = lang.Keyword.FUNCTION, lexeme = nil},
			lang.Token{type = .DELIMITER, kind = lang.Delimiter.SEMICOLUMN, lexeme = nil},
		},
		{
			lang.Token{type = .IDENTIFIER, kind = lang.Literal.DECIMAL, lexeme = []rune{'x'}},
			lang.Token{type = .OPERATOR, kind = lang.Operator.EQUAL, lexeme = nil},
			lang.Token{type = .LITERAL, kind = lang.Literal.DECIMAL, lexeme = []rune{'1', '1'}},
			lang.Token{type = .DELIMITER, kind = lang.Delimiter.SEMICOLUMN, lexeme = nil},
		},
		{
			lang.Token{type = .IDENTIFIER, kind = lang.Literal.DECIMAL, lexeme = []rune{'x'}},
			lang.Token{type = .OPERATOR, kind = lang.Operator.EQUAL, lexeme = nil},
			lang.Token{type = .LITERAL, kind = lang.Literal.DECIMAL, lexeme = []rune{'1'}},
			lang.Token{type = .OPERATOR, kind = lang.Operator.DOT, lexeme = nil},
			lang.Token{type = .LITERAL, kind = lang.Literal.DECIMAL, lexeme = []rune{'2'}},
			lang.Token{type = .DELIMITER, kind = lang.Delimiter.SEMICOLUMN, lexeme = nil},
		},
		{
			lang.Token{type = .IDENTIFIER, kind = lang.Literal.DECIMAL, lexeme = []rune{'x'}},
			lang.Token{type = .OPERATOR, kind = lang.Operator.EQUAL, lexeme = nil},
			lang.Token{type = .IDENTIFIER, kind = lang.Literal.DECIMAL, lexeme = []rune{'a'}},
			lang.Token{type = .OPERATOR, kind = lang.Operator.PLUS, lexeme = nil},
			lang.Token{type = .IDENTIFIER, kind = lang.Literal.DECIMAL, lexeme = []rune{'b'}},
			lang.Token{type = .DELIMITER, kind = lang.Delimiter.SEMICOLUMN, lexeme = nil},
		},
		{
			lang.Token{type = .IDENTIFIER, kind = lang.Literal.DECIMAL, lexeme = []rune{'x'}},
			lang.Token{type = .OPERATOR, kind = lang.Operator.EQUAL, lexeme = nil},
			lang.Token{type = .IDENTIFIER, kind = lang.Literal.DECIMAL, lexeme = []rune{'a'}},
			lang.Token{type = .OPERATOR, kind = lang.Operator.MINUS, lexeme = nil},
			lang.Token{type = .IDENTIFIER, kind = lang.Literal.DECIMAL, lexeme = []rune{'b'}},
			lang.Token{type = .DELIMITER, kind = lang.Delimiter.SEMICOLUMN, lexeme = nil},
		},
		{
			lang.Token{type = .IDENTIFIER, kind = lang.Literal.DECIMAL, lexeme = []rune{'x'}},
			lang.Token{type = .OPERATOR, kind = lang.Operator.EQUAL, lexeme = nil},
			lang.Token {
				type = .LITERAL,
				kind = lang.Literal.TEXT,
				lexeme = []rune{'"', 'h', 'e', 'l', 'l', 'o', ' ', 'w', 'o', 'r', 'l', 'd', '"'},
			},
			lang.Token{type = .DELIMITER, kind = lang.Delimiter.SEMICOLUMN, lexeme = nil},
		},
		{
			lang.Token{type = .IDENTIFIER, kind = lang.Literal.DECIMAL, lexeme = []rune{'x'}},
			lang.Token{type = .OPERATOR, kind = lang.Operator.EQUAL, lexeme = nil},
			lang.Token {
				type = .LITERAL,
				kind = lang.Literal.CHARACTER,
				lexeme = []rune{'\'', 'a', '\''},
			},
			lang.Token{type = .DELIMITER, kind = lang.Delimiter.SEMICOLUMN, lexeme = nil},
		},
		{
			lang.Token{type = .IDENTIFIER, kind = lang.Literal.DECIMAL, lexeme = []rune{'x'}},
			lang.Token{type = .OPERATOR, kind = lang.Operator.EQUAL, lexeme = nil},
			lang.Token{type = .IDENTIFIER, kind = lang.Literal.DECIMAL, lexeme = []rune{'f'}},
			lang.Token{type = .DELIMITER, kind = lang.Delimiter.SEMICOLUMN, lexeme = nil},
		},
		{
			lang.Token{type = .IDENTIFIER, kind = lang.Literal.DECIMAL, lexeme = []rune{'x'}},
			lang.Token{type = .OPERATOR, kind = lang.Operator.EQUAL, lexeme = nil},
			lang.Token{type = .IDENTIFIER, kind = lang.Literal.DECIMAL, lexeme = []rune{'f'}},
			lang.Token{type = .DELIMITER, kind = lang.Delimiter.PAREN_OPEN, lexeme = nil},
			lang.Token{type = .IDENTIFIER, kind = lang.Literal.DECIMAL, lexeme = []rune{'a'}},
			lang.Token{type = .DELIMITER, kind = lang.Delimiter.COMMA, lexeme = nil},
			lang.Token{type = .IDENTIFIER, kind = lang.Literal.DECIMAL, lexeme = []rune{'b'}},
			lang.Token{type = .DELIMITER, kind = lang.Delimiter.PAREN_CLOSE, lexeme = nil},
			lang.Token{type = .DELIMITER, kind = lang.Delimiter.SEMICOLUMN, lexeme = nil},
		},
		{
			lang.Token{type = .KEYWORD, kind = lang.Keyword.RETURN, lexeme = nil},
			lang.Token{type = .IDENTIFIER, kind = lang.Literal.DECIMAL, lexeme = []rune{'x'}},
			lang.Token{type = .DELIMITER, kind = lang.Delimiter.SEMICOLUMN, lexeme = nil},
		},
		{
			lang.Token{type = .KEYWORD, kind = lang.Keyword.IF, lexeme = nil},
			lang.Token{type = .IDENTIFIER, kind = lang.Literal.DECIMAL, lexeme = []rune{'a'}},
			lang.Token{type = .OPERATOR, kind = lang.Operator.LESS, lexeme = nil},
			lang.Token{type = .IDENTIFIER, kind = lang.Literal.DECIMAL, lexeme = []rune{'b'}},
			lang.Token{type = .DELIMITER, kind = lang.Delimiter.BRACE_OPEN, lexeme = nil},
			lang.Token{type = .KEYWORD, kind = lang.Keyword.RETURN, lexeme = nil},
			lang.Token{type = .IDENTIFIER, kind = lang.Literal.DECIMAL, lexeme = []rune{'a'}},
			lang.Token{type = .DELIMITER, kind = lang.Delimiter.SEMICOLUMN, lexeme = nil},
			lang.Token{type = .DELIMITER, kind = lang.Delimiter.BRACE_CLOSE, lexeme = nil},
		},
		{
			lang.Token{type = .KEYWORD, kind = lang.Keyword.IF, lexeme = nil},
			lang.Token{type = .IDENTIFIER, kind = lang.Literal.DECIMAL, lexeme = []rune{'a'}},
			lang.Token{type = .OPERATOR, kind = lang.Operator.MORE, lexeme = nil},
			lang.Token{type = .IDENTIFIER, kind = lang.Literal.DECIMAL, lexeme = []rune{'b'}},
			lang.Token{type = .DELIMITER, kind = lang.Delimiter.BRACE_OPEN, lexeme = nil},
			lang.Token{type = .KEYWORD, kind = lang.Keyword.RETURN, lexeme = nil},
			lang.Token{type = .IDENTIFIER, kind = lang.Literal.DECIMAL, lexeme = []rune{'b'}},
			lang.Token{type = .DELIMITER, kind = lang.Delimiter.SEMICOLUMN, lexeme = nil},
			lang.Token{type = .DELIMITER, kind = lang.Delimiter.BRACE_CLOSE, lexeme = nil},
		},
		{
			lang.Token{type = .KEYWORD, kind = lang.Keyword.IF, lexeme = nil},
			lang.Token{type = .IDENTIFIER, kind = lang.Literal.DECIMAL, lexeme = []rune{'a'}},
			lang.Token{type = .OPERATOR, kind = lang.Operator.LESS_EQUAL, lexeme = nil},
			lang.Token{type = .IDENTIFIER, kind = lang.Literal.DECIMAL, lexeme = []rune{'b'}},
			lang.Token{type = .DELIMITER, kind = lang.Delimiter.BRACE_OPEN, lexeme = nil},
			lang.Token{type = .IDENTIFIER, kind = lang.Literal.DECIMAL, lexeme = []rune{'x'}},
			lang.Token{type = .OPERATOR, kind = lang.Operator.EQUAL, lexeme = nil},
			lang.Token{type = .IDENTIFIER, kind = lang.Literal.DECIMAL, lexeme = []rune{'a'}},
			lang.Token{type = .OPERATOR, kind = lang.Operator.PLUS, lexeme = nil},
			lang.Token{type = .LITERAL, kind = lang.Literal.DECIMAL, lexeme = []rune{'1'}},
			lang.Token{type = .DELIMITER, kind = lang.Delimiter.SEMICOLUMN, lexeme = nil},
			lang.Token{type = .DELIMITER, kind = lang.Delimiter.BRACE_CLOSE, lexeme = nil},
		},
		{
			lang.Token{type = .KEYWORD, kind = lang.Keyword.IF, lexeme = nil},
			lang.Token{type = .IDENTIFIER, kind = lang.Literal.DECIMAL, lexeme = []rune{'a'}},
			lang.Token{type = .OPERATOR, kind = lang.Operator.MORE_EQUAL, lexeme = nil},
			lang.Token{type = .IDENTIFIER, kind = lang.Literal.DECIMAL, lexeme = []rune{'b'}},
			lang.Token{type = .DELIMITER, kind = lang.Delimiter.BRACE_OPEN, lexeme = nil},
			lang.Token{type = .IDENTIFIER, kind = lang.Literal.DECIMAL, lexeme = []rune{'x'}},
			lang.Token{type = .OPERATOR, kind = lang.Operator.EQUAL, lexeme = nil},
			lang.Token{type = .IDENTIFIER, kind = lang.Literal.DECIMAL, lexeme = []rune{'b'}},
			lang.Token{type = .OPERATOR, kind = lang.Operator.MINUS, lexeme = nil},
			lang.Token{type = .LITERAL, kind = lang.Literal.DECIMAL, lexeme = []rune{'1'}},
			lang.Token{type = .DELIMITER, kind = lang.Delimiter.SEMICOLUMN, lexeme = nil},
			lang.Token{type = .DELIMITER, kind = lang.Delimiter.BRACE_CLOSE, lexeme = nil},
		},
		{
			lang.Token{type = .KEYWORD, kind = lang.Keyword.IF, lexeme = nil},
			lang.Token{type = .IDENTIFIER, kind = lang.Literal.DECIMAL, lexeme = []rune{'a'}},
			lang.Token{type = .OPERATOR, kind = lang.Operator.EQUAL_EQUAL, lexeme = nil},
			lang.Token{type = .IDENTIFIER, kind = lang.Literal.DECIMAL, lexeme = []rune{'b'}},
			lang.Token{type = .DELIMITER, kind = lang.Delimiter.BRACE_OPEN, lexeme = nil},
			lang.Token{type = .KEYWORD, kind = lang.Keyword.RETURN, lexeme = nil},
			lang.Token{type = .IDENTIFIER, kind = lang.Literal.DECIMAL, lexeme = []rune{'a'}},
			lang.Token{type = .DELIMITER, kind = lang.Delimiter.SEMICOLUMN, lexeme = nil},
			lang.Token{type = .DELIMITER, kind = lang.Delimiter.BRACE_CLOSE, lexeme = nil},
		},
		{
			lang.Token{type = .KEYWORD, kind = lang.Keyword.DECLARE, lexeme = nil},
			lang.Token{type = .IDENTIFIER, kind = lang.Literal.DECIMAL, lexeme = []rune{'x'}},
			lang.Token{type = .KEYWORD, kind = lang.Keyword.INT, lexeme = nil},
			lang.Token{type = .DELIMITER, kind = lang.Delimiter.SEMICOLUMN, lexeme = nil},
			lang.Token{type = .KEYWORD, kind = lang.Keyword.DECLARE, lexeme = nil},
			lang.Token{type = .IDENTIFIER, kind = lang.Literal.DECIMAL, lexeme = []rune{'y'}},
			lang.Token{type = .KEYWORD, kind = lang.Keyword.INT, lexeme = nil},
			lang.Token{type = .DELIMITER, kind = lang.Delimiter.SEMICOLUMN, lexeme = nil},
			lang.Token{type = .IDENTIFIER, kind = lang.Literal.DECIMAL, lexeme = []rune{'x'}},
			lang.Token{type = .OPERATOR, kind = lang.Operator.EQUAL, lexeme = nil},
			lang.Token{type = .LITERAL, kind = lang.Literal.DECIMAL, lexeme = []rune{'1', '1'}},
			lang.Token{type = .DELIMITER, kind = lang.Delimiter.SEMICOLUMN, lexeme = nil},
			lang.Token{type = .IDENTIFIER, kind = lang.Literal.DECIMAL, lexeme = []rune{'y'}},
			lang.Token{type = .OPERATOR, kind = lang.Operator.EQUAL, lexeme = nil},
			lang.Token{type = .LITERAL, kind = lang.Literal.DECIMAL, lexeme = []rune{'2', '5'}},
			lang.Token{type = .DELIMITER, kind = lang.Delimiter.SEMICOLUMN, lexeme = nil},
			lang.Token{type = .IDENTIFIER, kind = lang.Literal.DECIMAL, lexeme = []rune{'x'}},
			lang.Token{type = .OPERATOR, kind = lang.Operator.EQUAL, lexeme = nil},
			lang.Token{type = .IDENTIFIER, kind = lang.Literal.DECIMAL, lexeme = []rune{'x'}},
			lang.Token{type = .OPERATOR, kind = lang.Operator.PLUS, lexeme = nil},
			lang.Token{type = .IDENTIFIER, kind = lang.Literal.DECIMAL, lexeme = []rune{'y'}},
			lang.Token{type = .DELIMITER, kind = lang.Delimiter.SEMICOLUMN, lexeme = nil},
			lang.Token{type = .KEYWORD, kind = lang.Keyword.IF, lexeme = nil},
			lang.Token{type = .IDENTIFIER, kind = lang.Literal.DECIMAL, lexeme = []rune{'x'}},
			lang.Token{type = .OPERATOR, kind = lang.Operator.MORE_EQUAL, lexeme = nil},
			lang.Token{type = .IDENTIFIER, kind = lang.Literal.DECIMAL, lexeme = []rune{'y'}},
			lang.Token{type = .DELIMITER, kind = lang.Delimiter.BRACE_OPEN, lexeme = nil},
			lang.Token{type = .KEYWORD, kind = lang.Keyword.RETURN, lexeme = nil},
			lang.Token{type = .IDENTIFIER, kind = lang.Literal.DECIMAL, lexeme = []rune{'x'}},
			lang.Token{type = .DELIMITER, kind = lang.Delimiter.SEMICOLUMN, lexeme = nil},
			lang.Token{type = .DELIMITER, kind = lang.Delimiter.BRACE_CLOSE, lexeme = nil},
		},

		// Second source string
		{
			lang.Token{type = .KEYWORD, kind = lang.Keyword.DECLARE, lexeme = nil},
			lang.Token {
				type = .IDENTIFIER,
				kind = lang.Literal.DECIMAL,
				lexeme = []rune{'m', 'e', 's', 's', 'a', 'g', 'e'},
			},
			lang.Token{type = .KEYWORD, kind = lang.Keyword.INT, lexeme = nil},
			lang.Token{type = .DELIMITER, kind = lang.Delimiter.SEMICOLUMN, lexeme = nil},
			lang.Token{type = .KEYWORD, kind = lang.Keyword.DECLARE, lexeme = nil},
			lang.Token {
				type = .IDENTIFIER,
				kind = lang.Literal.DECIMAL,
				lexeme = []rune{'c', 'h', 'a', 'r', 'a', 'c', 't', 'e', 'r'},
			},
			lang.Token{type = .KEYWORD, kind = lang.Keyword.INT, lexeme = nil},
			lang.Token{type = .DELIMITER, kind = lang.Delimiter.SEMICOLUMN, lexeme = nil},
			lang.Token{type = .KEYWORD, kind = lang.Keyword.DECLARE, lexeme = nil},
			lang.Token {
				type = .IDENTIFIER,
				kind = lang.Literal.DECIMAL,
				lexeme = []rune{'n', 'u', 'm', 'b', 'e', 'r'},
			},
			lang.Token{type = .KEYWORD, kind = lang.Keyword.INT, lexeme = nil},
			lang.Token{type = .DELIMITER, kind = lang.Delimiter.SEMICOLUMN, lexeme = nil},
			lang.Token {
				type = .IDENTIFIER,
				kind = lang.Literal.DECIMAL,
				lexeme = []rune{'m', 'e', 's', 's', 'a', 'g', 'e'},
			},
			lang.Token{type = .OPERATOR, kind = lang.Operator.EQUAL, lexeme = nil},
			lang.Token {
				type = .LITERAL,
				kind = lang.Literal.TEXT,
				lexeme = []rune {
					'"',
					'h',
					'e',
					'l',
					'l',
					'o',
					' ',
					'p',
					'a',
					'r',
					's',
					'e',
					'r',
					'"',
				},
			},
			lang.Token{type = .DELIMITER, kind = lang.Delimiter.SEMICOLUMN, lexeme = nil},
			lang.Token {
				type = .IDENTIFIER,
				kind = lang.Literal.DECIMAL,
				lexeme = []rune{'c', 'h', 'a', 'r', 'a', 'c', 't', 'e', 'r'},
			},
			lang.Token{type = .OPERATOR, kind = lang.Operator.EQUAL, lexeme = nil},
			lang.Token {
				type = .LITERAL,
				kind = lang.Literal.CHARACTER,
				lexeme = []rune{'\'', 'x', '\''},
			},
			lang.Token{type = .DELIMITER, kind = lang.Delimiter.SEMICOLUMN, lexeme = nil},
			lang.Token {
				type = .IDENTIFIER,
				kind = lang.Literal.DECIMAL,
				lexeme = []rune{'n', 'u', 'm', 'b', 'e', 'r'},
			},
			lang.Token{type = .OPERATOR, kind = lang.Operator.EQUAL, lexeme = nil},
			lang.Token{type = .LITERAL, kind = lang.Literal.DECIMAL, lexeme = []rune{'1', '2'}},
			lang.Token{type = .OPERATOR, kind = lang.Operator.DOT, lexeme = nil},
			lang.Token{type = .LITERAL, kind = lang.Literal.DECIMAL, lexeme = []rune{'7', '5'}},
			lang.Token{type = .DELIMITER, kind = lang.Delimiter.SEMICOLUMN, lexeme = nil},
			lang.Token{type = .KEYWORD, kind = lang.Keyword.IF, lexeme = nil},
			lang.Token {
				type = .IDENTIFIER,
				kind = lang.Literal.DECIMAL,
				lexeme = []rune{'n', 'u', 'm', 'b', 'e', 'r'},
			},
			lang.Token{type = .OPERATOR, kind = lang.Operator.EQUAL_EQUAL, lexeme = nil},
			lang.Token{type = .LITERAL, kind = lang.Literal.DECIMAL, lexeme = []rune{'1', '2'}},
			lang.Token{type = .OPERATOR, kind = lang.Operator.DOT, lexeme = nil},
			lang.Token{type = .LITERAL, kind = lang.Literal.DECIMAL, lexeme = []rune{'7', '5'}},
			lang.Token{type = .DELIMITER, kind = lang.Delimiter.BRACE_OPEN, lexeme = nil},
			lang.Token{type = .KEYWORD, kind = lang.Keyword.RETURN, lexeme = nil},
			lang.Token {
				type = .IDENTIFIER,
				kind = lang.Literal.DECIMAL,
				lexeme = []rune{'m', 'e', 's', 's', 'a', 'g', 'e'},
			},
			lang.Token{type = .DELIMITER, kind = lang.Delimiter.SEMICOLUMN, lexeme = nil},
			lang.Token{type = .DELIMITER, kind = lang.Delimiter.BRACE_CLOSE, lexeme = nil},
		},

		// Third source string
		{
			// if a<b {}
			lang.Token{type = .KEYWORD, kind = lang.Keyword.IF, lexeme = nil},
			lang.Token{type = .IDENTIFIER, kind = lang.Literal.DECIMAL, lexeme = []rune{'a'}},
			lang.Token{type = .OPERATOR, kind = lang.Operator.LESS, lexeme = nil},
			lang.Token{type = .IDENTIFIER, kind = lang.Literal.DECIMAL, lexeme = []rune{'b'}},
			lang.Token{type = .DELIMITER, kind = lang.Delimiter.BRACE_OPEN, lexeme = nil},
			lang.Token{type = .DELIMITER, kind = lang.Delimiter.BRACE_CLOSE, lexeme = nil},

			// if a<=b {}
			lang.Token{type = .KEYWORD, kind = lang.Keyword.IF, lexeme = nil},
			lang.Token{type = .IDENTIFIER, kind = lang.Literal.DECIMAL, lexeme = []rune{'a'}},
			lang.Token{type = .OPERATOR, kind = lang.Operator.LESS_EQUAL, lexeme = nil},
			lang.Token{type = .IDENTIFIER, kind = lang.Literal.DECIMAL, lexeme = []rune{'b'}},
			lang.Token{type = .DELIMITER, kind = lang.Delimiter.BRACE_OPEN, lexeme = nil},
			lang.Token{type = .DELIMITER, kind = lang.Delimiter.BRACE_CLOSE, lexeme = nil},

			// if a>b {}
			lang.Token{type = .KEYWORD, kind = lang.Keyword.IF, lexeme = nil},
			lang.Token{type = .IDENTIFIER, kind = lang.Literal.DECIMAL, lexeme = []rune{'a'}},
			lang.Token{type = .OPERATOR, kind = lang.Operator.MORE, lexeme = nil},
			lang.Token{type = .IDENTIFIER, kind = lang.Literal.DECIMAL, lexeme = []rune{'b'}},
			lang.Token{type = .DELIMITER, kind = lang.Delimiter.BRACE_OPEN, lexeme = nil},
			lang.Token{type = .DELIMITER, kind = lang.Delimiter.BRACE_CLOSE, lexeme = nil},

			// if a>=b {}
			lang.Token{type = .KEYWORD, kind = lang.Keyword.IF, lexeme = nil},
			lang.Token{type = .IDENTIFIER, kind = lang.Literal.DECIMAL, lexeme = []rune{'a'}},
			lang.Token{type = .OPERATOR, kind = lang.Operator.MORE_EQUAL, lexeme = nil},
			lang.Token{type = .IDENTIFIER, kind = lang.Literal.DECIMAL, lexeme = []rune{'b'}},
			lang.Token{type = .DELIMITER, kind = lang.Delimiter.BRACE_OPEN, lexeme = nil},
			lang.Token{type = .DELIMITER, kind = lang.Delimiter.BRACE_CLOSE, lexeme = nil},

			// if a==b {}
			lang.Token{type = .KEYWORD, kind = lang.Keyword.IF, lexeme = nil},
			lang.Token{type = .IDENTIFIER, kind = lang.Literal.DECIMAL, lexeme = []rune{'a'}},
			lang.Token{type = .OPERATOR, kind = lang.Operator.EQUAL_EQUAL, lexeme = nil},
			lang.Token{type = .IDENTIFIER, kind = lang.Literal.DECIMAL, lexeme = []rune{'b'}},
			lang.Token{type = .DELIMITER, kind = lang.Delimiter.BRACE_OPEN, lexeme = nil},
			lang.Token{type = .DELIMITER, kind = lang.Delimiter.BRACE_CLOSE, lexeme = nil},

			// a=b;
			lang.Token{type = .IDENTIFIER, kind = lang.Literal.DECIMAL, lexeme = []rune{'a'}},
			lang.Token{type = .OPERATOR, kind = lang.Operator.EQUAL, lexeme = nil},
			lang.Token{type = .IDENTIFIER, kind = lang.Literal.DECIMAL, lexeme = []rune{'b'}},
			lang.Token{type = .DELIMITER, kind = lang.Delimiter.SEMICOLUMN, lexeme = nil},

			// a=a+b;
			lang.Token{type = .IDENTIFIER, kind = lang.Literal.DECIMAL, lexeme = []rune{'a'}},
			lang.Token{type = .OPERATOR, kind = lang.Operator.EQUAL, lexeme = nil},
			lang.Token{type = .IDENTIFIER, kind = lang.Literal.DECIMAL, lexeme = []rune{'a'}},
			lang.Token{type = .OPERATOR, kind = lang.Operator.PLUS, lexeme = nil},
			lang.Token{type = .IDENTIFIER, kind = lang.Literal.DECIMAL, lexeme = []rune{'b'}},
			lang.Token{type = .DELIMITER, kind = lang.Delimiter.SEMICOLUMN, lexeme = nil},

			// a=a-b;
			lang.Token{type = .IDENTIFIER, kind = lang.Literal.DECIMAL, lexeme = []rune{'a'}},
			lang.Token{type = .OPERATOR, kind = lang.Operator.EQUAL, lexeme = nil},
			lang.Token{type = .IDENTIFIER, kind = lang.Literal.DECIMAL, lexeme = []rune{'a'}},
			lang.Token{type = .OPERATOR, kind = lang.Operator.MINUS, lexeme = nil},
			lang.Token{type = .IDENTIFIER, kind = lang.Literal.DECIMAL, lexeme = []rune{'b'}},
			lang.Token{type = .DELIMITER, kind = lang.Delimiter.SEMICOLUMN, lexeme = nil},
		},
	}

	for v, i in tokenArrays {

		// if i == 9 || i == 18 {
		arr := lang.Tokenise(runes[i], &trie)

		if !tokenArrMatch(arr, v) {

			fmt.printf("i = %d\n", i)

			js, ok := json.marshal(arr, json.Marshal_Options{pretty = true, use_enum_names = true})
			fmt.printf("%s\n", js)
			js, ok = json.marshal(v, json.Marshal_Options{pretty = true, use_enum_names = true})
			fmt.printf("%s\n", js)

		}

		exp(t, tokenArrMatch(arr, v))
		delete(arr)
	}
}
