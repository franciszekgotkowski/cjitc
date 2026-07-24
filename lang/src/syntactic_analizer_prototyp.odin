package langlang

GTree_Error :: enum {
	OK,
}

GrammarValue :: union {
	ProductionGroup,
	Production,
	Expression,
	Alternative,
	Term,
	Group,
	Option,
	Repetition,
}

GrammarNode :: struct {
	value: Token,
	nodes: [dynamic]^GrammarNode,
}
GNode :: GrammarNode

GrammarTrie :: struct {
	root: GrammarNode,
}
GTrie :: GrammarTrie

// GTrie_Delete :: proc(trie: ^GTrie) {
// 	Trie_Delete(Token, trie)
// }

// GTrie_Initialize :: proc() -> GTrie {
// 	return Trie_Initialize(Token)
// }

// GTrie_Contains :: proc(trie: ^GTrie, word: []Token) -> bool {
// 	return Trie_Contains(Token, trie, word)
// }

// GTrie_AppendWord :: proc(trie: ^GTrie, word: []Token) -> TrieError {
// 	return Trie_AppendWord(Token, trie, word)
// }


// UnrollProductionGroup :: proc(prodg: ^ProductionGroup, arr: ^[dynamic]Token) {
// 	assert(prodg != nil, "nilptr")
// 	assert(arr != nil, "nilptr")

// 	for v, i in prodg {
// 		UnrollProduction(&prodg[i], arr)
// 	}
// }

// UnrollProduction :: proc(prod: ^Production, arr: ^[dynamic]Token) {
// 	assert(prod != nil, "nilptr")
// 	assert(arr != nil, "nilptr")

// 	UnrollExpression(&prod.expression, arr)
// }

// UnrollExpression :: proc(expr: ^Expression, arr: ^[dynamic]Token) {
// 	assert(expr != nil, "nilptr")
// 	assert(arr != nil, "nilptr")

// 	UnrollAlternative(&expr.alternative, arr)
// 	UnrollRepetition(&expr.alternatives, arr)
// }

// UnrollAlternative :: proc(alt: ^Alternative, arr: ^[dynamic]Token) {
// 	assert(alt != nil, "nilptr")
// 	assert(arr != nil, "nilptr")

// 	UnrollTerm(&alt.term, arr)
// 	UnrollRepetition(&alt.terms, arr)
// }

// UnrollTerm :: proc(term: ^Term, arr: ^[dynamic]Token) {
// 	assert(term != nil, "nilptr")
// 	assert(arr != nil, "nilptr")

// 	switch v in term.value {
// 	case ProductionName:
// 		// TODO: jakoś zadbać o wyszukiwanie odpowiednich Produkcji, lub nawet zmianę na ProductionGroup
// 		assert(false)
// 	case Token:
// 		UnrollToken(&term.value.(Token), arr)
// 	case Group:
// 		UnrollGroup(&term.value.(Group), arr)
// 	case Option:
// 		UnrollOption(&term.value.(Option), arr)
// 	case Repetition:
// 		UnrollRepetition(&term.value.(Repetition), arr)
// 	}
// }

// UnrollGroup :: proc(group: ^Group, arr: ^[dynamic]Token) {
// 	assert(group != nil, "nilptr")
// 	assert(arr != nil, "nilptr")

// 	for val, i in group {
// 		switch v in val {
// 		case Expression:
// 			UnrollExpression(&group[i].(Expression), arr)
// 		case ProductionGroup:
// 			UnrollProductionGroup(&group[i].(ProductionGroup), arr)
// 		}
// 	}

// }

// UnrollOption :: proc(opt: ^Option, arr: ^[dynamic]Token) {
// 	assert(opt != nil, "nilptr")
// 	assert(arr != nil, "nilptr")
// }

// UnrollRepetition :: proc(rep: ^Repetition, arr: ^[dynamic]Token) {
// 	assert(rep != nil, "nilptr")
// 	assert(arr != nil, "nilptr")
// }

// UnrollToken :: proc(token: ^Token, arr: ^[dynamic]Token) {
// 	assert(token != nil, "nilptr")
// 	assert(arr != nil, "nilptr")
// }

// ProductionGroup_Serialize :: proc(group: ^ProductionGroup) -> GTrie {
// 	assert(group != nil, "nilptr")

// 	trie := GTrie_Initialize()
// 	arr: [dynamic]Token


// 	return trie
// }
