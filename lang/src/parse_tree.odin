package langlang

import "core:fmt"

ParseError :: enum {
	OK,
	ALLOCATOR_ERROR,
	COULD_NOT_MATCH,
}

PNode :: ParseNode

ParseNode :: struct {
	token: Token `json="token"`,
	next:  []Token `json="next"`,
}

PTree :: ParseTree

ParseTree :: struct {
	root: ParseNode `json="root"`,
}

ParseTokens :: proc(tokens: []Token) -> (PTree, ParseError) {
	assert(tokens != nil, "nilptr")

	tree := PTree{}

	ConsumeToken :: proc(
		pnode: ^PNode,
		gnode: ^GNode,
		tokens: []Token,
		idx: int,
	) -> (
		PNode,
		ParseError,
	) {
		assert(pnode != nil, "nilptr")
		assert(gnode != nil, "nilptr")
		assert(tokens != nil, "nilptr")

		token := tokens[idx]

		assert(false, "not implemented")
		return {}, .OK

	}

	assert(false, "not implemented")
	return {}, .OK
}
