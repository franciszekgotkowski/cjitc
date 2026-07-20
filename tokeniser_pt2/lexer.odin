package main

import "core:fmt"
import "core:unicode/utf8"

LexerError :: enum {
	OK,
	NOT_A_TOKEN,
	NOT_A_LITERAL,
	NOT_AN_OPERATOR,
	NOT_A_DELIMITER,
}

Token :: struct {
	type:   TokenType,
	kind:   TokenKind,
	lexeme: []rune,
}

IdentifyWord :: proc(code: []rune, words: ^Trie) -> ([]rune, TokenType, TokenKind) {
	assert(code != nil)
	assert(words != nil)

	wordLenght := 0

	wordFound := false
	wordFinalCharacter := 0
	wordFinalNode: ^TrieNode = nil

	node := &words.root
	for v, i in code {
		tempNode, err := TrieNode_FetchChild(node, v)
		if err == .OK {
			wordLenght += 1
			node = tempNode

			if node.isWord {
				wordFound = true
				wordFinalCharacter := v
				wordFinalNode = node
			}
		} else {
			assert(err == .CHILD_DOES_NOT_EXIST)
			// assert(wordLenght > 0)
			if wordFound {
				return code[:wordLenght], wordFinalNode.tokenType, wordFinalNode.tokenKind
			} else {
				return code[:wordLenght], .IDENTIFIER, Keyword.INT
			}
		}
	}

	if wordFound {
		return code[:wordLenght], wordFinalNode.tokenType, wordFinalNode.tokenKind
	} else {
		return code[:wordLenght], .IDENTIFIER, Keyword.INT
	}

	// assert(false)
	// return nil, .IDENTIFIER, Keyword.INT
}

IdentifyLiteral :: proc(code: []rune) -> ([]rune, Literal, LexerError) {
	assert(code != nil)

	literalType: Literal

	if code[0] == LiteralCharSeparator {
		literalType = .CHARACTER
	} else if code[0] == LiteralTextSeparator {
		literalType = .TEXT
	} else if IsDigit(code[0]) {
		literalType = .DECIMAL
	} else {
		return nil, .DECIMAL, .NOT_A_LITERAL
	}

	IdentifyCharLiteral :: proc(code: []rune) -> ([]rune, LexerError) {
		assert(code != nil)
		assert(code[0] == LiteralCharSeparator)

		i := 1

		for code[i] != LiteralCharSeparator && i < len(code) {
			i += 1
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

		for code[i] != LiteralTextSeparator && i < len(code) {
			i += 1
		}

		if i == 1 {
			return nil, .NOT_A_TOKEN
		}

		return code[:i], .OK
	}

	IdentifyDecimalLiteral :: proc(code: []rune) -> ([]rune, LexerError) {
		assert(code != nil)

		i := 0
		for IsOmitable(code[i]) == false {
			if IsDigit(code[i]) {
				i += 1
			} else {
				return nil, .NOT_A_TOKEN
			}
		}

		return code[:i], .OK
	}

	switch literalType {
	case .CHARACTER:
		lexeme, err := IdentifyCharLiteral(code)
		if err == .OK {
			return lexeme, .CHARACTER, .OK
		} else {
			return nil, .CHARACTER, .NOT_A_TOKEN
		}
	case .TEXT:
		lexeme, err := IdentifyTextLiteral(code)
		if err == .OK {
			return lexeme, .TEXT, .OK
		} else {
			return nil, .TEXT, .NOT_A_TOKEN
		}
	case .DECIMAL:
		lexeme, err := IdentifyDecimalLiteral(code)
		if err == .OK {
			return lexeme, .DECIMAL, .OK
		} else {
			return nil, .DECIMAL, .NOT_A_TOKEN
		}
	}

	assert(false)
	return nil, .CHARACTER, .NOT_A_TOKEN
}

CreateIdentifier :: proc(code: []rune) -> []rune {
	assert(code != nil)
	assert(IsDigit(code[0]) == false)
	assert(IsOmitable(code[0]) == false)

	lexeme: []rune

	for v, i in code {
		if IsOmitable(v) {
			lexeme = code[:i]
			break
		}
		if op, err := IsOperator(v); err == .OK {
			lexeme = code[:i]
			break
		}
		if op, err := IsDelimiter(v); err == .OK {
			lexeme = code[:i]
			break
		}
		lexeme = code[:i + 1]
	}

	return lexeme
}

Tokenise :: proc(code: []rune, words: ^Trie) -> [dynamic]Token {
	assert(code != nil)

	c := code

	tokens: [dynamic]Token = {}

	for len(c) > 0 {
		lexeme, type, kind := IdentifyWord(c, words)

		// sprawdzam czy nie mam do czynia ze znanym słowem
		if len(lexeme) > 0 {
			append(&tokens, Token{type = type, kind = kind, lexeme = lexeme})
			c = c[len(lexeme):]
			continue
		}

		// sprawdzam czy to nie jest pomijalny znak
		if IsOmitable(c[0]) {
			c = c[1:]
			continue
		}

		// sprawdzam czy to nie jest literal
		_lexeme, literal, err := IdentifyLiteral(c)
		assert(err == .OK || err == .NOT_A_TOKEN || err == .NOT_A_LITERAL)
		if err == .OK {
			append(&tokens, Token{type = .LITERAL, kind = literal, lexeme = _lexeme})
			c = c[len(_lexeme):]
			continue
		} else if err == .NOT_A_TOKEN {
			fmt.println("Tokenisation Error!")
			delete(tokens)
			return nil
		}

		// muszę mieć do czynienia z identifierem
		lexeme = CreateIdentifier(c)
		if len(lexeme) == 0 {
			fmt.println("Tokenisation Error!")
			delete(tokens)
			return nil
		} else {
			append(&tokens, Token{type = .IDENTIFIER, kind = literal, lexeme = lexeme})
			c = c[len(lexeme):]
			continue
		}


	}

	return tokens
}

IsOperator :: proc(r: rune) -> (Operator, LexerError) {
	s := utf8.runes_to_string([]rune{r})
	for v, i in OperatorValues {
		if s == v {
			return i, .OK
		}
	}
	return .LESS, .NOT_AN_OPERATOR
}

IsDelimiter :: proc(r: rune) -> (Delimiter, LexerError) {
	s := utf8.runes_to_string([]rune{r})
	for v, i in DelimiterValues {
		if s == v {
			return i, .OK
		}
	}
	return .SEMICOLUMN, .NOT_A_DELIMITER
}
