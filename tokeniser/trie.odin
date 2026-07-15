package main

import "base:runtime"
import "core:fmt"

TrieNode :: struct {
	children: [dynamic]TrieNode,
	value:    rune,
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
TrieNode_New :: proc(r: rune) -> TrieNode {
	return TrieNode{children = {}, value = r}
}

TrieNode_AppendRune :: proc(node: ^TrieNode, r: rune) -> (Trie_Error, i32) {
	assert(node != nil)
	exists: bool = false
	for v, i in node.children {
		if r == v.value {
			exists = true
			return Trie_Error.ALREADY_EXISTS, i32(i)
		}
	}

	_, err := append(&node.children, TrieNode_New(r))
	idx := len(node.children) - 1
	if err != runtime.Allocator_Error.None {
		return Trie_Error.ALLOCATION_ERROR, -1
	} else {
		return Trie_Error.OK, i32(idx)
	}
}

TrieNode_AppendRuneSlice :: proc(node: ^TrieNode, r: []rune) -> Trie_Error {
	assert(node != nil)
	assert(r != nil)
	if len(r) == 0 {
		return Trie_Error.OK
	}

	err, i := TrieNode_AppendRune(node, r[0])
	if err == Trie_Error.ALLOCATION_ERROR {
		return Trie_Error.ALLOCATION_ERROR
	}

	err = TrieNode_AppendRuneSlice(&node.children[i], r[1:])
	if err != Trie_Error.ALLOCATION_ERROR {
		return Trie_Error.OK
	} else {
		return Trie_Error.ALLOCATION_ERROR
	}
}

TrieNode_DFS_Print :: proc(node: ^TrieNode, offset: i32) {
	assert(node != nil)
	fmt.printf("%c", node.value)
	for _, i in node.children {
		TrieNode_DFS_Print(&node.children[i], offset + 1)
		if len(node.children) != 1 {
			fmt.printf("\n")
		}
		for j in 0 ..< offset {
			fmt.printf(" ")
		}
	}
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
	return Trie{size = 0, root = TrieNode_New(' ')}
}


Trie_Append :: proc(trie: ^Trie, r: []rune) -> Trie_Error {
	assert(trie != nil)
	assert(r != nil)

	if len(r) == 0 {
		return Trie_Error.OK
	}

	err := TrieNode_AppendRuneSlice(&trie.root, r)
	if err != .ALLOCATION_ERROR {
		trie.size += len(r)
		return .OK
	} else {
		return .ALLOCATION_ERROR
	}
}

Trie_Delete :: proc(trie: ^Trie) {
	assert(trie != nil)
	if trie.size > 0 {
		TrieNode_Free(&trie.root)
	}
}

Trie_Print :: proc(trie: ^Trie) {
	assert(trie != nil)

	if trie.size > 0 {
		TrieNode_DFS_Print(&trie.root, 1)
	}
}
