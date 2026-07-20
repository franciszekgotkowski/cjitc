package main

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
				wordFinalCharacter := i
				wordFinalNode = node
			}
		} else {
			assert(err == .CHILD_DOES_NOT_EXIST)
			assert(wordLenght > 0)
			if wordFound {
				return code[:wordLenght], wordFinalNode.tokenType, wordFinalNode.tokenKind
			} else {
				return code[:wordLenght], .IDENTIFIER, Keyword.INT
			}
		}
	}

	assert(false)
	return nil, .IDENTIFIER, Keyword.INT
}

Tokenise :: proc(code: []rune) -> [dynamic]Token {
	assert(code != nil)

	idx: int

	return nil
}
