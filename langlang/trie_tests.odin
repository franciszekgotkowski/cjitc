package main

import "core:testing"
import "core:unicode/utf8"

Prepare_Trie_test :: proc() -> Trie {
	tokens: [dynamic]Token = {}
	defer {
		for v, i in tokens {
			delete(tokens[i].lexeme)
		}
		delete(tokens)
	}

	for v, i in TokenType {
		#partial switch v {
		case .KEYWORD:
			for vv, j in Keyword {
				lex := utf8.string_to_runes(KeywordValues[vv])
				append(&tokens, Token{type = v, kind = vv, lexeme = lex})
			}
		case .OPERATOR:
			for vv, j in Operator {
				lex := utf8.string_to_runes(OperatorValues[vv])
				append(&tokens, Token{type = v, kind = vv, lexeme = lex})
			}
		case .DELIMITER:
			for vv, j in Delimiter {
				lex := utf8.string_to_runes(DelimiterValues[vv])
				append(&tokens, Token{type = v, kind = vv, lexeme = lex})
			}
		case:
			continue
		}
	}

	trie := Trie_Initialize()
	for v, i in tokens {
		Trie_AppendWord(&trie, v.lexeme, v.type, v.kind)
	}
	return trie

}

@(test)
TrieNode_Contains_test :: proc(t: ^testing.T) {
	node: TrieNode = {}

	contains, _ := TrieNode_Contains(&node, 'r')
	defer TrieNode_Delete(&node)

	testing.expect(t, !contains, "Node should not contain anything")

	values: []rune = {'r', '4', '-', ' ', '\n', '1'}

	for v, i in values {
		b, i := TrieNode_Contains(&node, v)
		testing.expectf(t, !b, "should not contain '%c'", v)
	}

	for v, i in values {
		append(&node.children, TrieNode{value = v})
	}

	for v, i in values {
		b, i := TrieNode_Contains(&node, v)
		testing.expectf(t, b, "should contain '%c' at index %d", v, i)
	}
	#reverse for v, i in values {
		b, i := TrieNode_Contains(&node, v)
		testing.expectf(t, b, "should contain '%c' at index %d", v, i)
	}

	nonValues: []rune = {'e', '8', '=', '_', '\t', '2'}
	for v, i in nonValues {
		b, i := TrieNode_Contains(&node, v)
		testing.expectf(t, !b, "should not contain '%c'", v)
	}
}

@(test)
TrieNode_AppendChild_test :: proc(t: ^testing.T) {
	trie := Prepare_Trie_test()
	defer Trie_Delete(&trie)

	runes: []rune = {'i', 'f', '[', ']', 'g'}
	errors: []TrieError = {.ALREADY_EXISTS, .ALREADY_EXISTS, .OK, .OK, .OK}

	for v, i in runes {
		idx, err := TrieNode_AppendChild(&trie.root, true, runes[i], .KEYWORD, .INT)
		testing.expectf(t, err == errors[i], "Tesing if '%c' can be added to root\n", runes[i])
	}
}

@(test)
TrieNode_Delete_test :: proc(t: ^testing.T) {
	trie := Prepare_Trie_test()

	testing.expect(t, len(trie.root.children) > 0)
	TrieNode_Delete(&trie.root)
	testing.expect(t, len(trie.root.children) == 0)
}

@(test)
Trie_AppendWord_test :: proc(t: ^testing.T) {
	trie := Prepare_Trie_test()
	defer Trie_Delete(&trie)

	words: [][]rune = {
		utf8.string_to_runes("float"),
		utf8.string_to_runes("int"),
		utf8.string_to_runes("decide"),
		utf8.string_to_runes("()"),
		utf8.string_to_runes("function"),
		utf8.string_to_runes("functional"),
	}
	defer {
		for _, i in words {
			delete(words[i])
		}
	}
	errs: []TrieError = {.OK, .ALREADY_EXISTS, .OK, .OK, .ALREADY_EXISTS, .OK}

	for v, i in words {
		err := Trie_AppendWord(&trie, words[i])
		testing.expect(t, err == errs[i], "")
	}

}
