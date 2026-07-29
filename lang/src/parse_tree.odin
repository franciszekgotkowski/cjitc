package langlang

import "core:encoding/json"
import "core:fmt"

ParseError :: enum {
	OK,
	ALLOCATOR_ERROR,
	COULD_NOT_MATCH,
	LOGICAL_ERROR,
	INCORRECT_INPUT,
	NO_CHILDREN,
	// TOKENS_PARSED,
}

PNode :: ParseNode

ParseNode :: struct {
	value: union {
		Token,
		ProductionName,
	} `json="value"`,
	next:  [dynamic]ParseNode `json="next"`,
}

PTree :: ParseTree

ParseTree :: struct {
	root: ParseNode `json="root"`,
}

ParseTokens :: proc(pnode: PNode, gnode: ^GNode, tokens: []Token) -> (PNode, []Token, ParseError) {

	ParseGnodeChildren :: proc(
		pnode: PNode,
		gnode: ^GNode,
		tokens: []Token,
	) -> (
		PNode,
		[]Token,
		ParseError,
	) {
		assert(len(gnode.nodes) > 0)
		for v, i in gnode.nodes {
			p, toks, err := ParseTokens(pnode, gnode.nodes[i], tokens)
			if err == .OK {
				return p, toks, .OK
			}
		}
		return {}, {}, .COULD_NOT_MATCH
	}

	assert(gnode != nil, "nilptr")

	// jeżeli trafi na produkcję to tworzy dla niej nowy pnode, jeżeli zostanie stworzony z sukcesem, może ją dodać, w przeciwnym wypadku zawsze dodajemy do pnode'a
	// zawsze przed wykonaniem sprawdzamy czy tokens nie jest puste

	if len(tokens) == 0 {
		return pnode, nil, .INCORRECT_INPUT
	}
	pnode := pnode

	// if v, ok := gnode.prodStart.?; ok {
	// 	newp := PNode {
	// 		value = v,
	// 	}
	// 	assert(false, "not implemented")
	// }

	switch val in gnode.value {
	case Token:
		if match(val, tokens[0]) {
			append(&pnode.next, PNode{value = val})
			if len(gnode.nodes) == 0 do return pnode, tokens, .OK

			p, t, err := ParseGnodeChildren(pnode, gnode, tokens[1:])
			if err == .OK {
				return p, t, .OK
			} else {
				if gnode.endOfRepetition {
					return pnode, tokens, .OK
				}
				return {}, nil, err
			}
		} else {
			return {}, nil, .COULD_NOT_MATCH
		}
	case DoArray:
		// valuesMatched := false
		for v, i in val.value {
			p, t, err := ParseTokens(pnode, val.value[i], tokens[:])
			if err == .OK {
				// valuesMatched = true
				if len(gnode.nodes) == 0 do return p, t, .OK

				p2, t2, err2 := ParseGnodeChildren(p, gnode, t[1:])
				if err2 == .OK {
					return p2, t2, .OK
				}
				if gnode.endOfRepetition {
					return p, t, .OK
				}
			}
		}

		if val.skippable {
			// if len(gnode.nodes) == 0 do return {}, nil, .COULD_NOT_MATCH
			if len(gnode.nodes) == 0 do return pnode, tokens, .OK
			p, t, err := ParseGnodeChildren(pnode, gnode, tokens[:])
			if err == .OK {
				return p, t, .OK
			} else {
				return {}, nil, .COULD_NOT_MATCH
			}
		} else {
			return {}, nil, .COULD_NOT_MATCH
		}

	}

	assert(false, "not implemented")
	return {}, {}, .LOGICAL_ERROR
}
