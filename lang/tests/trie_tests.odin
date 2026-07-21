package main

import lang "../src"
import "core:testing"
import "core:unicode/utf8"

// exp :: testing.expect

@(private)
Prepare_Trie :: proc() -> lang.Trie {
	tokens: [dynamic]lang.Token = {}
	defer {
		for v, i in tokens {
			delete(tokens[i].lexeme)
		}
		delete(tokens)
	}

	for v, i in lang.TokenType {
		#partial switch v {
		case .KEYWORD:
			for vv, j in lang.Keyword {
				lex := utf8.string_to_runes(lang.KeywordValues[vv])
				append(&tokens, lang.Token{type = v, kind = vv, lexeme = lex})
			}
		case .OPERATOR:
			for vv, j in lang.Operator {
				lex := utf8.string_to_runes(lang.OperatorValues[vv])
				append(&tokens, lang.Token{type = v, kind = vv, lexeme = lex})
			}
		case .DELIMITER:
			for vv, j in lang.Delimiter {
				lex := utf8.string_to_runes(lang.DelimiterValues[vv])
				append(&tokens, lang.Token{type = v, kind = vv, lexeme = lex})
			}
		case:
			continue
		}
	}

	trie := lang.Trie_Initialize()
	for v, i in tokens {
		lang.Trie_AppendWord(&trie, v.lexeme, v.type, v.kind)
	}
	return trie

}

@(test)
TrieNode_Contains_test :: proc(t: ^testing.T) {
	node: lang.TrieNode = {}

	contains, _ := lang.TrieNode_Contains(&node, 'r')
	defer lang.TrieNode_Delete(&node)

	testing.expect(t, !contains, "Node should not contain anything")

	values: []rune = {'r', '4', '-', ' ', '\n', '1'}

	for v, i in values {
		b, i := lang.TrieNode_Contains(&node, v)
		testing.expectf(t, !b, "should not contain '%c'", v)
	}

	for v, i in values {
		append(&node.children, lang.TrieNode{value = v})
	}

	for v, i in values {
		b, i := lang.TrieNode_Contains(&node, v)
		testing.expectf(t, b, "should contain '%c' at index %d", v, i)
	}
	#reverse for v, i in values {
		b, i := lang.TrieNode_Contains(&node, v)
		testing.expectf(t, b, "should contain '%c' at index %d", v, i)
	}

	nonValues: []rune = {'e', '8', '=', '_', '\t', '2'}
	for v, i in nonValues {
		b, i := lang.TrieNode_Contains(&node, v)
		testing.expectf(t, !b, "should not contain '%c'", v)
	}
}

@(test)
TrieNode_AppendChild_test :: proc(t: ^testing.T) {
	trie := Prepare_Trie()
	defer lang.Trie_Delete(&trie)

	runes: []rune = {'i', 'f', '[', ']', 'g'}
	errors: []lang.TrieError = {.ALREADY_EXISTS, .ALREADY_EXISTS, .OK, .OK, .OK}

	for v, i in runes {
		idx, err := lang.TrieNode_AppendChild(&trie.root, true, runes[i], .KEYWORD, .INT)
		testing.expectf(t, err == errors[i], "Tesing if '%c' can be added to root\n", runes[i])
	}
}

@(test)
TrieNode_Delete_test :: proc(t: ^testing.T) {
	trie := Prepare_Trie()

	testing.expect(t, len(trie.root.children) > 0)
	lang.TrieNode_Delete(&trie.root)
	testing.expect(t, len(trie.root.children) == 0)
}

@(test)
Trie_AppendWord_test :: proc(t: ^testing.T) {
	trie := Prepare_Trie()
	defer lang.Trie_Delete(&trie)

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
	errs: []lang.TrieError = {.OK, .ALREADY_EXISTS, .OK, .OK, .ALREADY_EXISTS, .OK}

	for v, i in words {
		err := lang.Trie_AppendWord(&trie, words[i])
		testing.expect(t, err == errs[i], "")
	}

	exp(t, !lang.Trie_Contains(&trie, {'g', 'i', 'g', 'a'}))
	err := lang.Trie_AppendWord(&trie, {'g', 'i', 'g', 'a'})
	exp(t, err == .OK)
	exp(t, lang.Trie_Contains(&trie, {'g', 'i', 'g', 'a'}))
	exp(t, !lang.Trie_Contains(&trie, {'g', 'i', 'g'}))
	lang.Trie_AppendWord(&trie, {'g', 'i', 'g'})
	exp(t, err == .OK)
	exp(t, lang.Trie_Contains(&trie, {'g', 'i', 'g'}))

}
