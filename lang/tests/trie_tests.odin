package tests

import lang "../src"
import "core:testing"
import "core:unicode/utf8"

// @(private)
// Prepare_Trie :: proc() -> lang.Trie(lang.RuneWithToken) {
// 	tokens: [dynamic][dynamic]lang.RuneWithToken = {}
// 	defer {
// 		for v, i in tokens {
// 			delete(tokens[i])
// 		}
// 		delete(tokens)
// 	}

// 	for v, i in lang.TokenType {
// 		lex: []rune
// 		#partial switch v {
// 		case .KEYWORD:
// 			for vv, j in lang.Keyword {
// 				lex := utf8.string_to_runes(lang.KeywordValues[vv])
// 				defer delete(lex)

// 				arr := lang.RuneWithTokenArr(lang.Token{type = v, kind = vv, lexeme = lex})
// 				append(&tokens, arr)
// 			}
// 		case .OPERATOR:
// 			for vv, j in lang.Operator {
// 				lex := utf8.string_to_runes(lang.OperatorValues[vv])
// 				defer delete(lex)

// 				arr := lang.RuneWithTokenArr(lang.Token{type = v, kind = vv, lexeme = lex})
// 				append(&tokens, arr)
// 			}
// 		case .DELIMITER:
// 			for vv, j in lang.Delimiter {
// 				lex := utf8.string_to_runes(lang.DelimiterValues[vv])
// 				defer delete(lex)

// 				arr := lang.RuneWithTokenArr(lang.Token{type = v, kind = vv, lexeme = lex})
// 				append(&tokens, arr)
// 			}
// 		case:
// 			continue
// 		}

// 	}

// 	trie := lang.Trie_Initialize(lang.RuneWithToken)
// 	for v, i in tokens {
// 		slice: []lang.RuneWithToken = v[:]
// 		lang.Trie_AppendWord(lang.RuneWithToken, &trie, slice)
// 	}
// 	return trie

// }

// @(test)
// TrieNode_Contains_test :: proc(t: ^testing.T) {
// 	node: lang.TrieNode(lang.RuneWithToken) = {}

// 	contains, _ := lang.TrieNode_Contains(lang.RuneWithToken, &node, lang.RuneWithToken{'r', nil})
// 	defer lang.TrieNode_Delete(lang.RuneWithToken, &node)

// 	testing.expect(t, !contains, "Node should not contain anything")

// 	// values: []rune = {'r', '4', '-', ' ', '\n', '1'}
// 	values: []lang.RuneWithToken = {
// 		{'r', nil},
// 		{'4', nil},
// 		{'-', nil},
// 		{' ', nil},
// 		{'\n', nil},
// 		{'1', nil},
// 	}

// 	for v, i in values {
// 		b, i := lang.TrieNode_Contains(lang.RuneWithToken, &node, v)
// 		testing.expectf(t, !b, "should not contain '%c'", v)
// 	}

// 	for v, i in values {
// 		append(&node.children, lang.TrieNode(lang.RuneWithToken){value = v})
// 	}

// 	for v, i in values {
// 		b, i := lang.TrieNode_Contains(lang.RuneWithToken, &node, v)
// 		testing.expectf(t, b, "should contain '%c' at index %d", v, i)
// 	}
// 	#reverse for v, i in values {
// 		b, i := lang.TrieNode_Contains(lang.RuneWithToken, &node, v)
// 		testing.expectf(t, b, "should contain '%c' at index %d", v, i)
// 	}

// 	nonValues: []lang.RuneWithToken = {
// 		{',', nil},
// 		{'8', nil},
// 		{'=', nil},
// 		{'_', nil},
// 		{'\t', nil},
// 		{'2', nil},
// 	}

// 	for v, i in nonValues {
// 		b, i := lang.TrieNode_Contains(lang.RuneWithToken, &node, v)
// 		testing.expectf(t, !b, "should not contain '%c'", v)
// 	}
// }

// // @(test)
// // TrieNode_AppendChild_test :: proc(t: ^testing.T) {
// // 	trie := Prepare_Trie()
// // 	defer lang.Trie_Delete(lang.RuneWithToken, &trie)

// // 	runes: []rune = {'i', 'f', '[', ']', 'g'}
// // 	errors: []lang.TrieError = {.ALREADY_EXISTS, .ALREADY_EXISTS, .OK, .OK, .OK}

// // 	for v, i in runes {
// // 		idx, err := lang.TrieNode_AppendChild(&trie.root, true, runes[i], .KEYWORD, .INT)
// // 		testing.expectf(t, err == errors[i], "Tesing if '%c' can be added to root\n", runes[i])
// // 	}
// // }

// // @(test)
// // TrieNode_Delete_test :: proc(t: ^testing.T) {
// // 	trie := Prepare_Trie()

// // 	testing.expect(t, len(trie.root.children) > 0)
// // 	lang.TrieNode_Delete(&trie.root)
// // 	testing.expect(t, len(trie.root.children) == 0)
// // }

// // Trie_AppendWord_test :: proc(t: ^testing.T) {
// // 	trie := Prepare_Trie()
// // 	defer lang.Trie_Delete(&trie)

// // 	words: [][]rune = {
// // 		utf8.string_to_runes("float"),
// // 		utf8.string_to_runes("int"),
// // 		utf8.string_to_runes("decide"),
// // 		utf8.string_to_runes("()"),
// // 		utf8.string_to_runes("function"),
// // 		utf8.string_to_runes("functional"),
// // 	}
// // 	defer {
// // 		for _, i in words {
// // 			delete(words[i])
// // 		}
// // 	}
// // 	errs: []lang.TrieError = {.OK, .ALREADY_EXISTS, .OK, .OK, .ALREADY_EXISTS, .OK}

// // 	for v, i in words {
// // 		err := lang.Trie_AppendWord(&trie, words[i])
// // 		testing.expect(t, err == errs[i], "")
// // 	}

// // 	exp(t, !lang.Trie_Contains(&trie, {'g', 'i', 'g', 'a'}))
// // 	err := lang.Trie_AppendWord(&trie, {'g', 'i', 'g', 'a'})
// // 	exp(t, err == .OK)
// // 	exp(t, lang.Trie_Contains(&trie, {'g', 'i', 'g', 'a'}))
// // 	exp(t, !lang.Trie_Contains(&trie, {'g', 'i', 'g'}))
// // 	lang.Trie_AppendWord(&trie, {'g', 'i', 'g'})
// // 	exp(t, err == .OK)
// // 	exp(t, lang.Trie_Contains(&trie, {'g', 'i', 'g'}))

// // }
