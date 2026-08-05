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
	union {
		// PNode,
		PNode,
		[2]PNode,
	},
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
					switch val in p {
					case PNode:
						return val, toks, .OK
					case [2]PNode:
						pnode := pnode
						append(&pnode.next, val[0])
						for v, _ in val[1].next {
							append(&pnode.next, v)
						}
						return pnode, toks, .OK
					}

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
		if err == .OK {

			switch val in pnew {
			case ParseNode:
				v := val
				v.value = name
				append(&pnode.next, v)
			case [2]ParseNode:
				v := val[0]
				v.value = name
				append(&pnode.next, v)
				for v, i in val[1].next {
					append(&pnode.next, v)
				}
			}

			return pnode, t, .OK
		}
	}

	switch val in gnode.value {
	case Token:
		if match(val, tokens[0]) {
			append(&pnode.next, PNode{value = val})
			if len(gnode.nodes) == 0 do return pnode, tokens[1:], .OK

			if gnode.endOfRepetition {

				p, t, err := ParseGnodeChildren({}, gnode, tokens[1:])

				if err == .OK {
					return [2]PNode{pnode, p}, t, .OK
				}

				return PNode{}, nil, err

			} else {
				p, t, err := ParseGnodeChildren(pnode, gnode, tokens[1:])
				if err == .OK {
					return p, t, .OK
				} else {
					return PNode{}, nil, .COULD_NOT_MATCH
				}
			}
		} else {
			return PNode{}, nil, .COULD_NOT_MATCH
		}
	case DoArray:
		// valuesMatched := false
		for v, i in val.value {
			p, t, err := ParseTokens(pnode, val.value[i], tokens[:])
			if err == .OK {
				_, ok := p.(PNode)
				assert(ok)
				if len(gnode.nodes) == 0 do return p, t, .OK

				if gnode.endOfRepetition {
					p2, t2, err2 := ParseGnodeChildren({}, gnode, t)
					if err2 == .OK {
						return [2]PNode{p.(PNode), p2}, t2, .OK
						// return p2, t2, .OK
					} else {
						return p, t, .OK
					}
				} else {
					if gnode.prodStart != nil {
						p2, t2, err2 := ParseGnodeChildren(PNode{}, gnode, t)
						if err == .OK {
							return [2]PNode{p.(PNode), p2}, t2, .OK
						}
					} else {
						p2, t2, err2 := ParseGnodeChildren(p.(PNode), gnode, t)
						if err2 == .OK {
							return p2, t2, .OK
						}
					}
				}
			}
			if err == .SKIPPABLE {
				if len(gnode.nodes) == 0 do return {}, nil, .COULD_NOT_MATCH

				if gnode.endOfRepetition {
					p2, t2, err2 := ParseGnodeChildren({}, gnode, tokens)
					if err2 == .OK {
						return [2]PNode{p.(PNode), p2}, t2, .OK
						// return p2, t2, .OK
					} else {
						return p, t, .OK
					}
				} else {
					p2, t2, err2 := ParseGnodeChildren(p.(PNode), gnode, tokens)
					if err2 == .OK {
						return p2, t2, .OK
					}
				}

			}
		}

		if val.skippable {
			if len(gnode.nodes) == 0 do return PNode{}, nil, .SKIPPABLE
			// if len(gnode.nodes) == 0 do return pnode, tokens, .OK
			p, t, err := ParseGnodeChildren(pnode, gnode, tokens)
			if err == .OK {
				return p, t, .OK
			} else {
				return PNode{}, nil, .COULD_NOT_MATCH
			}
		} else {
			return PNode{}, nil, .COULD_NOT_MATCH
		}

	}

	assert(false, "should never happen")
	return PNode{}, {}, .LOGICAL_ERROR
}
