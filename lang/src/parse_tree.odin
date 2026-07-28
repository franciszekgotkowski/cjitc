package langlang

import "core:encoding/json"
import "core:fmt"

ParseError :: enum {
	OK,
	ALLOCATOR_ERROR,
	COULD_NOT_MATCH,
}

PNode :: ParseNode

ParseNode :: struct {
	value: union {
		Token,
		ProductionName,
	} `json="value"`,
	next:  []Token `json="next"`,
}

PTree :: ParseTree

ParseTree :: struct {
	root: ParseNode `json="root"`,
}

// ParseProduction :: proc(prod: ProductionName, tokens: [dynamic]Token) -> ParseError {
// }

// ParseTokens :: proc(tokens: []Token) -> (PTree, ParseError) {
// 	assert(tokens != nil, "nilptr")

// 	tree := PTree{}

// 	ConsumeToken :: proc(
// 		pnode: ^PNode,
// 		gnode: ^GNode,
// 		tokens: []Token,
// 		idx: int,
// 	) -> (
// 		PNode,
// 		int,
// 		ParseError,
// 	) {
// 		assert(pnode != nil, "nilptr")
// 		assert(gnode != nil, "nilptr")
// 		assert(tokens != nil, "nilptr")


// 		token := tokens[idx]
// 		g, err := GrammarNode_MatchToken(gnode, token)
// 		if err != .OK {
// 			js, _ := json.marshal(token, json.Marshal_Options{use_enum_names = true})
// 			fmt.printf("Could not match token:\t%s\tfrom grammar!\n", js)
// 			return {}, idx, .COULD_NOT_MATCH
// 		}

// 		js, _ := json.marshal(token, json.Marshal_Options{use_enum_names = true})
// 		fmt.printf("Currently on token:\t%s\tfrom grammar!\n", js)
// 		ConsumeToken(pnode, g, tokens, idx + 1)

// 		// assert(false, "not implemented")
// 		return {}, 0, .OK

// 	}

// 	gnode: GNode
// 	append(&gnode.nodes, &UnrolledProductions[ParseEntryPoint].?)

// 	ConsumeToken(&tree.root, &gnode, tokens, 0)
// 	// assert(false, "not implemented")
// 	return {}, .OK
// }
