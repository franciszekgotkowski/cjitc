package langlang

import "base:runtime"

TrieError :: enum {
	OK,
	ALREADY_EXISTS,
	ALLOCATION_ERROR,
	CHILD_DOES_NOT_EXIST,
}

TrieNode :: struct($T: typeid) {
	isWord:   bool `json:"is word"`,
	value:    T,
	children: [dynamic]TrieNode(T) `json:"children"`,
}

// Checks if TrieNode has a child with r value. If it has such child it will return true and index to this child
TrieNode_Contains :: proc($T: typeid, node: ^TrieNode(T), val: T) -> (bool, int) {
	assert(node != nil, "nilptr")
	contains := false

	for v, i in node.children {
		if match(val, v.value) {
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
	$T: typeid,
	node: ^TrieNode(T),
	isWord: bool,
	val: T,
) -> (
	int,
	TrieError,
) {
	assert(node != nil, "nilptr")

	if b, i := TrieNode_Contains(T, node, val); b {
		return i, .ALREADY_EXISTS
	}

	_, err := append(&node.children, TrieNode(T){isWord = isWord, children = {}, value = val})

	if err != runtime.Allocator_Error.None {
		return -1, .ALLOCATION_ERROR
	} else {
		return len(node.children) - 1, .OK
	}
}

// Fetches pointer to a child node that has r value
// Can return errors:
// .OK 							if everything went fine
// .CHILD_DOES_NOT_EXIST		if such child does not exist
TrieNode_FetchChild :: proc($T: typeid, node: ^TrieNode(T), val: T) -> (^TrieNode(T), TrieError) {
	assert(node != nil, "nilptr")

	for v, i in node.children {
		if match(val, v.value) {
			return &node.children[i], .OK
		}
	}
	return nil, .CHILD_DOES_NOT_EXIST
}

// Deletes nodes children and sets their array to len 0
TrieNode_Delete :: proc($T: typeid, node: ^TrieNode(T)) {
	assert(node != nil, "nilptr")

	for _, i in node.children {
		TrieNode_Delete(T, &node.children[i])
	}

	if len(node.children) > 0 {
		delete(node.children)
		clear(&node.children)
	}
}

Trie :: struct($T: typeid) {
	size: int,
	root: TrieNode(T),
}

Trie_Initialize :: proc($T: typeid) -> Trie(T) {
	return Trie(T){size = 0, root = TrieNode(T){isWord = false, children = {}, value = {}}}
}

// Allows for appending new words to the trie. It is made to accomodate tokens words so it takes in additional parameters
// Can return errors:
// .OK							if everything went well
// .ALLOCATION_ERROR			if memory could not be allocated
// .ALREADY_EXISTS				if word was already inside trie
Trie_AppendWord :: proc($T: typeid, trie: ^Trie(T), word: []T) -> TrieError {
	assert(trie != nil, "nilptr")
	assert(word != nil, "nilptr")
	currentNode := &trie.root

	addSize := 0
	for i in 0 ..< len(word) {
		idx, err := TrieNode_AppendChild(T, currentNode, i == len(word) - 1, word[i])
		assert(err == .OK || err == .ALREADY_EXISTS || err == .ALLOCATION_ERROR)
		if err == .ALLOCATION_ERROR {
			trie.size += addSize
			return .ALLOCATION_ERROR
		} else if err == .ALREADY_EXISTS {
			currentNode = &currentNode.children[idx]
			if i == len(word) - 1 {
				if currentNode.isWord {
					trie.size += addSize
					return .ALREADY_EXISTS
				} else {
					children := currentNode.children
					currentNode^ = TrieNode(T) {
						isWord   = true,
						children = children,
						value    = word[i],
					}
				}
			}
			continue
		} else {
			addSize += 1
			currentNode = &currentNode.children[idx]
		}

	}

	trie.size += addSize
	return .OK
}

// Deletes whole content of trie
Trie_Delete :: proc($T: typeid, trie: ^Trie(T)) {
	assert(trie != nil, "nilptr")
	trie.size = 0
	TrieNode_Delete(T, &trie.root)
}

// Checks if word is already a word inside a trie
Trie_Contains :: proc($T: typeid, trie: ^Trie(T), word: []T) -> bool {
	assert(trie != nil, "nilptr")
	assert(word != nil, "nilptr")

	node: ^TrieNode(T) = &trie.root

	for v, i in word {

		if c, idx := TrieNode_Contains(T, node, v); c {
			node = &node.children[idx]

			if i == len(word) - 1 {
				if node.isWord {
					return true
				} else {
					return false
				}
			}

		} else {
			return false
		}
	}

	return false

}

Int_Match :: proc(a, b: int) -> bool {
	return a == b
}

match :: proc {
	Token_Match,
	RuneWithToken_Match,
	Int_Match,
}
