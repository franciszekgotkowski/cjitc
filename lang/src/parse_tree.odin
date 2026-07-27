package langlang

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

ParseNode_AttachNext :: proc(p: ^PNode, g: ^GNode) -> (^PNode, ^GNode, ParseError) {
}
