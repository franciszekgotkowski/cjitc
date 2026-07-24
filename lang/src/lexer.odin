package langlang

import "core:fmt"
import "core:unicode/utf8"

LexerError :: enum {
	OK,
	NOT_A_TOKEN,
	NOT_A_LITERAL,
	NOT_AN_OPERATOR,
	NOT_AN_IDENTIFIER,
	NOT_A_DELIMITER,
}

Token :: struct {
	type:   TokenType,
	kind:   TokenKind,
	lexeme: []rune,
}

Token_Match :: proc(a, b: Token) -> bool {
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

IsIdentifierRune :: proc(r: rune) -> bool {
	if r == Underscore do return true
	for v, _ in CapitalLetter {
		if r == v do return true
	}
	for v, _ in Letter {
		if r == v do return true
	}
	for v, _ in Digit {
		if r == v do return true
	}
	return false
}

// Idenifies first word in code, that is present in words.
// It does not serve the purpose to check if the word is alredy inside trie
// If there is a word with a subword inside it, procedure will return the larger word
// If returned []rune is nil it means, procedure didn't find any word. In such case TokenType and TokenKind values are meaningless
IdentifyWord :: proc(code: []rune, words: ^Trie(RuneWithToken)) -> Token {
	assert(code != nil)
	assert(words != nil)

	wordLenght := 0

	wordFound := false
	wordFinalCharacter := rune(0)
	wordFinalLen := 0
	wordFinalNode: ^TrieNode(RuneWithToken) = nil

	node := &words.root
	for v, i in code {
		tempNode, err := TrieNode_FetchChild(RuneWithToken, node, RuneWithToken{v, nil})
		if err == .OK {
			wordLenght += 1
			node = tempNode

			if node.isWord {
				wordFound = true
				wordFinalCharacter = v
				wordFinalLen = wordFinalLen
				wordFinalNode = node
			}
		} else {
			assert(err == .CHILD_DOES_NOT_EXIST)
			if wordFound {

				// token, ok := wordFinalNode.value.token.?
				// assert(ok)
				// return Token{lexeme = code[:wordLenght], type = token.type, kind = token.kind}

				// _, del_err := IsDelimiter(v)
				// _, op_err := IsOperator(v)
				// omitable := IsOmitable(v)
				// if del_err == .OK || op_err == .OK || omitable {
				if !IsIdentifierRune(v) || IsDigit(v) {
					token, ok := wordFinalNode.value.token.?
					assert(ok)
					return Token{lexeme = code[:wordLenght], type = token.type, kind = token.kind}
				}
				return Token{}

			} else {
				return Token{}
			}
		}
	}

	if wordFound {
		token, ok := wordFinalNode.value.token.?
		assert(ok)
		return Token{lexeme = code[:wordLenght], type = token.type, kind = token.kind}
	} else {
		return Token{}
	}
}

// This procedure will try to identify literal which starts at code[0]. Currently it can identify char literal (with ''), text literal (with "") or decimal literal (comprised of digits)
// Can return errors:
// .OK						if everything went fine
// .NOT_A_LITERAL			if string is not a literal (it does not start with ", ', or a digit)
// .NOT_A_TOKEN				if token starts with " or ' but does not close with such rune
IdentifyLiteral :: proc(code: []rune) -> (Token, LexerError) {
	assert(code != nil)

	literalType: Literal

	if code[0] == LiteralCharSeparator {
		literalType = .CHARACTER
	} else if code[0] == LiteralTextSeparator {
		literalType = .TEXT
	} else if IsDigit(code[0]) {
		literalType = .DECIMAL
	} else {
		// return nil, .DECIMAL, .NOT_A_LITERAL
		return Token{}, .NOT_A_LITERAL
	}

	IdentifyCharLiteral :: proc(code: []rune) -> ([]rune, LexerError) {
		assert(code != nil)
		assert(code[0] == LiteralCharSeparator)

		i := 1

		for i < len(code) {
			if code[i] != LiteralCharSeparator {
				i += 1
			} else {
				i += 1
				break
			}
		}

		if i == 1 {
			return nil, .NOT_A_TOKEN
		}

		return code[:i], .OK
	}

	IdentifyTextLiteral :: proc(code: []rune) -> ([]rune, LexerError) {
		assert(code != nil)
		assert(code[0] == LiteralTextSeparator)

		i := 1
		for i < len(code) {
			if code[i] != LiteralTextSeparator {
				i += 1
			} else {
				i += 1
				break
			}
		}

		if i == 1 {
			return nil, .NOT_A_TOKEN
		}

		return code[:i], .OK
	}

	IdentifyDecimalLiteral :: proc(code: []rune) -> ([]rune, LexerError) {
		assert(code != nil)

		i := 0
		for i < len(code) {
			if IsDigit(code[i]) {
				i += 1
			} else {
				break
			}
		}

		return code[:i], .OK
	}

	switch literalType {
	case .CHARACTER:
		lexeme, err := IdentifyCharLiteral(code)
		if err == .OK {
			// return lexeme, .CHARACTER, .OK
			return Token{lexeme = lexeme, type = .LITERAL, kind = Literal.CHARACTER}, .OK
		} else {
			// return nil, .CHARACTER, .NOT_A_TOKEN
			return Token{}, .NOT_A_TOKEN
		}
	case .TEXT:
		lexeme, err := IdentifyTextLiteral(code)
		if err == .OK {
			// return lexeme, .TEXT, .OK
			return Token{lexeme = lexeme, type = .LITERAL, kind = Literal.TEXT}, .OK
		} else {
			// return nil, .TEXT, .NOT_A_TOKEN
			return Token{}, .NOT_A_TOKEN
		}
	case .DECIMAL:
		lexeme, err := IdentifyDecimalLiteral(code)
		if err == .OK {
			// return lexeme, .DECIMAL, .OK
			return Token{lexeme = lexeme, type = .LITERAL, kind = Literal.DECIMAL}, .OK
		} else {
			// return nil, .DECIMAL, .NOT_A_TOKEN
			return Token{}, .NOT_A_TOKEN
		}
	}

	assert(false)
	// return nil, .CHARACTER, .NOT_A_TOKEN
	return Token{}, .NOT_A_TOKEN
}

// This procedure creates an identifier looking at the start of code
// It will make an identifier from string of consecutive runes that are not  omitables, operators and delmiters
// Procedure will also check if string doesn't start with any of words inside of trie or if Identifier isn't a literal
// If it cannot create an identifier from the given code it will return nil []rune
CreateIdentifier :: proc(code: []rune, trie: ^Trie(RuneWithToken)) -> Token {
	assert(code != nil)
	runes := RuneWithTokenArr(Token{lexeme = code})
	defer delete(runes)
	if Trie_Contains(RuneWithToken, trie, runes[:]) {
		return Token{}
	}
	if token, err := IdentifyLiteral(code); err == .OK || err == .NOT_A_TOKEN {
		return Token{}
	} else {
		assert(err == .NOT_A_LITERAL)
	}

	// lexeme: []rune
	token := Token {
		type = .IDENTIFIER,
	}

	for v, i in code {

		if i == 0 {
			if !IsIdentifierRune(v) || IsDigit(v) {
				token.lexeme = code[:i]
				break
			}
		} else {
			if !IsIdentifierRune(v) {
				token.lexeme = code[:i]
				break
			}
		}

		// if IsOmitable(v) {
		// 	token.lexeme = code[:i]
		// 	break
		// }
		// if op, err := IsOperator(v); err == .OK {
		// 	token.lexeme = code[:i]
		// 	break
		// }
		// if op, err := IsDelimiter(v); err == .OK {
		// 	token.lexeme = code[:i]
		// 	break
		// }
		token.lexeme = code[:i + 1]
	}

	return token
}

// This procedure creates array of tokens made from the code and words Trie it was given
// If a tokenisation could not be finished array will be nil
Tokenise :: proc(code: []rune, words: ^Trie(RuneWithToken)) -> [dynamic]Token {
	assert(code != nil)

	c := code

	tokens: [dynamic]Token = {}

	for len(c) > 0 {
		token := IdentifyWord(c, words)

		// sprawdzam czy nie mam do czynia ze znanym słowem
		if len(token.lexeme) > 0 {
			append(&tokens, Token{type = token.type, kind = token.kind, lexeme = token.lexeme})
			c = c[len(token.lexeme):]
			continue
		}

		// sprawdzam czy to nie jest pomijalny znak
		if IsOmitable(c[0]) {
			c = c[1:]
			continue
		}

		// sprawdzam czy to nie jest literal
		// literal: Literal
		err: LexerError
		token, err = IdentifyLiteral(c)
		assert(err == .OK || err == .NOT_A_TOKEN || err == .NOT_A_LITERAL)
		if err == .OK {
			append(&tokens, Token{type = .LITERAL, kind = token.kind, lexeme = token.lexeme})
			c = c[len(token.lexeme):]
			continue
		} else if err == .NOT_A_TOKEN {
			fmt.println("Tokenisation Error!")
			delete(tokens)
			return nil
		}

		// muszę mieć do czynienia z identifierem
		token = CreateIdentifier(c, words)
		if len(token.lexeme) == 0 {
			fmt.println("Tokenisation Error!")
			delete(tokens)
			return nil
		} else {
			append(&tokens, token)
			c = c[len(token.lexeme):]
			continue
		}


	}

	return tokens
}

IsOperator :: proc(r: rune) -> (Operator, LexerError) {
	s := utf8.runes_to_string([]rune{r})
	defer delete(s)
	for v, i in OperatorValues {
		if s == v {
			return i, .OK
		}
	}
	return .LESS, .NOT_AN_OPERATOR
}

IsDelimiter :: proc(r: rune) -> (Delimiter, LexerError) {
	s := utf8.runes_to_string([]rune{r})
	defer delete(s)
	for v, i in DelimiterValues {
		if s == v {
			return i, .OK
		}
	}
	return .SEMICOLUMN, .NOT_A_DELIMITER
}

IsDigit :: proc(r: rune) -> bool {
	for v, _ in Digit {
		if r == v {
			return true
		}
	}
	return false
}

IsOmitable :: proc(r: rune) -> bool {
	for v, _ in Omitable {
		if r == v {
			return true
		}
	}
	return false
}
