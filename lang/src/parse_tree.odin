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
	SKIPPABLE,
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

ParseTokens :: proc(
	pnode: PNode,
	gnode: ^GNode,
	tokens: []Token,
	procStart := false,
) -> (
	PNode,
	[]Token,
	ParseError,
) {

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

		if len(tokens) > 0 {
			skippableFound := false
			for v, i in gnode.nodes {
				p, toks, err := ParseTokens(pnode, gnode.nodes[i], tokens)
				if err == .OK {
					return p, toks, .OK
				} else if err == .SKIPPABLE {
					skippableFound = true
				}
			}
			if skippableFound {
				return pnode, tokens, .OK
			}
		} else if len(tokens) == 0 {
			for v, i in gnode.nodes {
				p, toks, err := ParseTokens(pnode, gnode.nodes[i], tokens)
				if err == .SKIPPABLE {
					return pnode, tokens, .OK
				} else if err != .INCORRECT_INPUT {
					return {}, {}, .COULD_NOT_MATCH
				}
			}
			return pnode, tokens, .OK
		}

		return {}, {}, .COULD_NOT_MATCH
	}

	assert(gnode != nil, "nilptr")

	if len(tokens) == 0 {
		return pnode, nil, .INCORRECT_INPUT
	}
	pnode := pnode

	if name, ok := gnode.prodStart.?; ok && !procStart {
		pnew, t, err := ParseTokens(PNode{}, gnode, tokens, true)
		pnew.value = name
		if err == .OK {
			append(&pnode.next, pnew)
			return pnode, t, .OK
		}
	}

	switch val in gnode.value {
	case Token:
		if match(val, tokens[0]) {
			append(&pnode.next, PNode{value = val})
			if len(gnode.nodes) == 0 do return pnode, tokens[1:], .OK

			p, t, err := ParseGnodeChildren(pnode, gnode, tokens[1:])
			if err == .OK {
				return p, t, .OK
			} else {
				if gnode.endOfRepetition {
					return pnode, tokens[1:], .OK
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
				if len(gnode.nodes) == 0 do return p, t, .OK

				p2, t2, err2 := ParseGnodeChildren(p, gnode, t)
				if err2 == .OK {
					return p2, t2, .OK
				}
				if gnode.endOfRepetition {
					return p, t, .OK
				}
			}
			if err == .SKIPPABLE {
				if len(gnode.nodes) == 0 do return {}, nil, .COULD_NOT_MATCH

				p2, t2, err2 := ParseGnodeChildren(p, gnode, tokens)
				if err2 == .OK {
					return p2, t2, .OK
				}
				if gnode.endOfRepetition {
					return p, t, .OK
				}
			}
		}

		if val.skippable {
			if len(gnode.nodes) == 0 do return {}, nil, .SKIPPABLE
			// if len(gnode.nodes) == 0 do return pnode, tokens, .OK
			p, t, err := ParseGnodeChildren(pnode, gnode, tokens)
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
