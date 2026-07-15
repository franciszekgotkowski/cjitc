package main

import "base:runtime"
import "core:fmt"
import "core:unicode/utf8"

TrieNode :: struct {
	children: [dynamic]TrieNode,
	value:    rune,
	isWord:   bool,
	keyword:  Keyword,
}

Trie :: struct {
	size: int,
	root: TrieNode,
}

Trie_Error :: enum {
	OK,
	ALREADY_EXISTS,
	ALLOCATION_ERROR,
}
TrieNode_New :: proc(r: rune, isWord: bool, keyword: Keyword) -> TrieNode {
	return TrieNode{children = {}, value = r, isWord = isWord, keyword = keyword}
}

TrieNode_AppendRune :: proc(
	node: ^TrieNode,
	r: rune,
	isWord: bool,
	keyword: Keyword,
) -> (
	Trie_Error,
	i32,
) {
	assert(node != nil)
	exists: bool = false
	for v, i in node.children {
		if r == v.value {
			exists = true
			return Trie_Error.ALREADY_EXISTS, i32(i)
		}
	}

	_, err := append(&node.children, TrieNode_New(r, isWord, keyword))
	idx := len(node.children) - 1
	if err != runtime.Allocator_Error.None {
		return Trie_Error.ALLOCATION_ERROR, -1
	} else {
		return Trie_Error.OK, i32(idx)
	}
}

TrieNode_AppendRuneSlice :: proc(node: ^TrieNode, r: []rune, keyword: Keyword) -> Trie_Error {
	assert(node != nil)
	assert(r != nil)
	if len(r) == 0 {
		return Trie_Error.OK
	}

	isWord: bool = (len(r) == 1)
	err, i := TrieNode_AppendRune(node, r[0], isWord, keyword)
	if err == Trie_Error.ALLOCATION_ERROR {
		return Trie_Error.ALLOCATION_ERROR
	}

	err = TrieNode_AppendRuneSlice(&node.children[i], r[1:], keyword)
	if err != Trie_Error.ALLOCATION_ERROR {
		return Trie_Error.OK
	} else {
		return Trie_Error.ALLOCATION_ERROR
	}
}

Trie_Print :: proc(trie: ^Trie) {
	assert(trie != nil)
	t: [dynamic]rune = {}
	defer delete(t)

	if trie.size > 0 {
		// append(&t, 1, 2, 3)
		TrieNode_DFS_Print(&trie.root, &t, 1)
	}
}

TrieNode_DFS_Print :: proc(node: ^TrieNode, txt: ^[dynamic]rune, offset: i32) {
	assert(node != nil)
	assert(txt != nil)

	_, err := append(txt, node.value)
	assert(err == runtime.Allocator_Error.None)
	if node.isWord {
		fmt.printf("%s\tkeyword id: %v\n", txt^, node.keyword)
	}

	for _, i in node.children {
		TrieNode_DFS_Print(&node.children[i], txt, offset)
	}
	pop(txt)
}

TrieNode_Free :: proc(node: ^TrieNode) {
	assert(node != nil)
	for _, i in node.children {
		TrieNode_Free(&node.children[i])
		if node.children != nil {
			delete(node.children)
		}
	}
}

Trie_New :: proc() -> Trie {
	return Trie{size = 0, root = TrieNode_New(' ', false, Keyword(-1))}
}


Trie_AppendRunes :: proc(trie: ^Trie, r: []rune, keyword: Keyword) -> Trie_Error {
	assert(trie != nil)
	assert(r != nil)

	if len(r) == 0 {
		return Trie_Error.OK
	}

	err := TrieNode_AppendRuneSlice(&trie.root, r, keyword)
	if err != .ALLOCATION_ERROR {
		trie.size += len(r)
		return .OK
	} else {
		return .ALLOCATION_ERROR
	}
}

Trie_AppendString :: proc(trie: ^Trie, s: string, keyword: Keyword) -> Trie_Error {
	assert(trie != nil)
	r: []rune = utf8.string_to_runes(s)
	return Trie_AppendRunes(trie, r, keyword)
}

Trie_Append :: proc {
	Trie_AppendRunes,
	Trie_AppendString,
}

Trie_Delete :: proc(trie: ^Trie) {
	assert(trie != nil)
	if trie.size > 0 {
		TrieNode_Free(&trie.root)
	}
}
Trie_AppendAllRunes :: proc(trie: ^Trie, words: [][]rune) -> Trie_Error {
	assert(trie != nil)
	assert(words != nil)

	for _, i in words {
		err := Trie_Append(trie, words[i], Keyword(i))
		if err != Trie_Error.OK {
			return .ALLOCATION_ERROR
		}
	}
	return .OK
}

Trie_AppendAllStrings :: proc(trie: ^Trie, words: []string) -> Trie_Error {
	assert(trie != nil)
	assert(words != nil)

	for _, i in words {
		err := Trie_Append(trie, words[i], Keyword(i))
		if err != Trie_Error.OK {
			return .ALLOCATION_ERROR
		}
	}
	return .OK
}

Trie_AppendAll :: proc {
	Trie_AppendAllRunes,
	Trie_AppendAllStrings,
}

TrieNode_ChildExists :: proc(node: ^TrieNode, r: rune) -> (bool, int) {
	assert(node != nil)
	for v, i in node.children {
		if v.value == r {
			return true, i
		}
	}
	return false, -1
}

// Trie_ContainsWord_Runes :: proc(trie: ^Trie, r: []rune) -> bool {
// 	match :: proc(node: ^TrieNode, r: []rune) -> bool {
// 		for _, i in node.children {

// 			if node.children[i].value == r[0] {

// 				if len(r) == 1 {
// 					if node.isWord {
// 						return true
// 					} else {
// 						return false
// 					}
// 				}

// 				match(&node.children[i], r[1:])
// 			}
// 		}

// 	}
// }

// Trie_MatchesRunes :: proc(trie: ^Trie, r: []rune) -> [][]rune {

// 	matchExisting :: proc(trie: ^Trie, r: []rune, txt: ^[dynamic]rune) {
// 		assert(trie != nil)
// 		assert(r != nil)
// 		assert(txt != nil)


// 	}
// }
