package main

import "base:runtime"

TrieError :: enum {
	OK,
	ALREADY_EXISTS,
	ALLOCATION_ERROR,
	CHILD_DOES_NOT_EXIST,
}

TrieNode :: struct {
	isWord:    bool `json:"is word"`,
	value:     rune `json:"value"`,
	tokenType: TokenType `json:"token type"`,
	tokenKind: TokenKind `json:"token kind"`,
	children:  [dynamic]TrieNode `json:"children"`,
}

// Checks if TrieNode has a child with r value. If it has such child it will return true and index to this child
TrieNode_Contains :: proc(node: ^TrieNode, r: rune) -> (bool, int) {
	contains := false

	for v, i in node.children {
		if v.value == r {
			return true, i
		}
	}

	return false, -1
}

// Allows for appending child TrieNode to existing TrieNode
// Can return errors:
// TrieError.OK					if everything went well
// TrieError.ALLOCATION_ERROR	if memory could not be allocated
// TrieError.ALREADY_EXISTS		if child of such value already exists
TrieNode_AppendChild :: proc(
	node: ^TrieNode,
	isWord: bool,
	val: rune,
	type: TokenType,
	kind: TokenKind,
) -> (
	int,
	TrieError,
) {
	assert(node != nil)

	if b, i := TrieNode_Contains(node, val); b {
		return i, .ALREADY_EXISTS
	}

	_, err := append(
		&node.children,
		TrieNode{isWord = isWord, children = {}, value = val, tokenType = type, tokenKind = kind},
	)

	if err != runtime.Allocator_Error.None {
		return -1, .ALLOCATION_ERROR
	} else {
		return len(node.children) - 1, .OK
	}
}

TrieNode_FetchChild :: proc(node: ^TrieNode, r: rune) -> (^TrieNode, TrieError) {
	assert(node != nil)

	for v, i in node.children {
		if v.value == r {
			return &node.children[i], .OK
		}
	}
	return nil, .CHILD_DOES_NOT_EXIST
}

TrieNode_Delete :: proc(node: ^TrieNode) {
	assert(node != nil)

	for _, i in node.children {
		TrieNode_Delete(&node.children[i])
	}

	if len(node.children) > 0 {
		delete(node.children)
		clear(&node.children)
	}
}

Trie :: struct {
	size: int,
	root: TrieNode,
}

Trie_Initialize :: proc() -> Trie {
	return Trie {
		size = 0,
		root = TrieNode {
			isWord = false,
			tokenType = .KEYWORD,
			tokenKind = Keyword(.INT),
			children = {},
		},
	}
}

Trie_AppendWord :: proc(trie: ^Trie, word: []rune, type: TokenType, kind: TokenKind) -> TrieError {
	currentNode := &trie.root

	for i in 0 ..< len(word) {
		exists, idx := TrieNode_Contains(currentNode, word[i])
		if exists {
			currentNode = &currentNode.children[idx]
		} else {
			idx, err := TrieNode_AppendChild(currentNode, i == len(word) - 1, word[i], type, kind)
			currentNode = &currentNode.children[idx]

			trie.size += 1

			if err != .OK {
				return err
			}
		}
	}

	return .OK
}

Trie_Delete :: proc(trie: ^Trie) {
	trie.size = 0
	TrieNode_Delete(&trie.root)
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
