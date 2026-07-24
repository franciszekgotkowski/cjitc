package langlang

GrammarNode :: TrieNode(Token)
GNode :: GrammarNode

GrammarTrie :: Trie(Token)
GTrie :: GrammarTrie

GTrie_Delete :: proc(trie: ^Trie(Token)) {
	Trie_Delete(Token, trie)
}

GTrie_Initialize :: proc() -> GTrie {
	return Trie_Initialize(Token)
}

GTrie_Contains :: proc(trie: ^GTrie, word: []Token) -> bool {
	return Trie_Contains(Token, trie, word)
}

GTrie_AppendWord :: proc(trie: ^GTrie, word: []Token) -> TrieError {
	return Trie_AppendWord(Token, trie, word)
}

ProductionGroup_Serialize :: proc(group: ^ProductionGroup) -> GTrie {
	assert(group != nil, "nilptr")

	trie := GTrie_Initialize()


	return trie
}
