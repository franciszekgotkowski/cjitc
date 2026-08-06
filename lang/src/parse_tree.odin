package langlang

import "core:encoding/json"
import "core:fmt"
import "core:slice"

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

// Collapses a ParseTokens result into a single PNode. When it's already a
// [2]PNode, val[0] was built by extending whatever accumulator was passed
// into that call, so it already contains everything that came before -
// only val[1].next (the further continuation) needs merging in, not val[0]
// itself nested as a child. Every place that needs "the PNode I just
// matched" as a single value (to keep building on, or to re-pair into a
// new [2]PNode) must go through this instead of a raw `p.(PNode)` - `p`
// can legitimately be a [2]PNode here (e.g. a repetition that isn't the
// last term of its Alternative, like a function body's `{ STATEMENT }`
// followed by `}`), and a raw type assertion panics on that.
Flatten_ParseResult :: proc(p: union {
		PNode,
		[2]PNode,
	}) -> PNode {
	switch val in p {
	case PNode:
		return val
	case [2]PNode:
		result := val[0]
		result.next = slice.clone_to_dynamic(result.next[:])
		for v in val[1].next {
			append(&result.next, v)
		}
		return result
	}
	return {}
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
					// val[0] (if p is [2]PNode) was built by extending the
					// *same* pnode passed into ParseTokens above (not a
					// fresh {}), so it already contains everything pnode
					// had - Flatten_ParseResult merges val[1].next into it
					// without re-appending pnode's own content again.
					return Flatten_ParseResult(p), toks, .OK
				} else if err == .SKIPPABLE {
					skippableFound = true
				}
			}
			if skippableFound {
				return pnode, tokens, .OK
			}
		} else if len(tokens) == 0 {
			// Out of tokens before matching whatever comes next
			// (gnode.nodes[0]). That's fine (not a failure) if either:
			//
			//  - gnode is the closing element of a repetition cycle
			//    (gnode.nodes loops back to try another cycle - trying
			//    again is optional), or
			//  - gnode.nodes[0] is itself an optional construct (a
			//    skippable Group/Option/Repetition, e.g. MUL_EXPRESSIONS'
			//    trailing `{ MUL_OPERATORS UNARY_EXPRESSIONS }`) with
			//    nothing mandatory chained after it - so skipping it means
			//    we're genuinely done, not just that this one piece of a
			//    larger mandatory sequence is missing (contrast e.g.
			//    FUNCTION_CALL's optional arg list, which still has a
			//    mandatory ")" ";" chained after it - running out of
			//    tokens there must still fail).
			//
			// Otherwise gnode.nodes is a mandatory next step (the next
			// term of a fixed Alternative, or a non-final step inside a
			// repetition body) and running out of input here means the
			// whole thing failed to match, not that it's done.
			//
			// (ParseTokens always returns .INCORRECT_INPUT immediately for
			// empty tokens, regardless of what gnode.nodes[i] is, so that
			// can never itself tell us whether stopping here was allowed -
			// we have to inspect gnode/gnode.nodes[0] directly instead.)
			if gnode.endOfRepetition {
				return pnode, tokens, .OK
			}
			next := gnode.nodes[0]
			if next_arr, ok := next.value.(DoArray);
			   ok && next_arr.skippable && len(next.nodes) == 0 {
				return pnode, tokens, .OK
			}
			return {}, {}, .COULD_NOT_MATCH
		}

		return {}, {}, .COULD_NOT_MATCH
	}

	assert(gnode != nil, "nilptr")

	if len(tokens) == 0 {
		return pnode, nil, .INCORRECT_INPUT
	}
	pnode := pnode
	pnode.next = slice.clone_to_dynamic(pnode.next[:])

	if name, ok := gnode.prodStart.?; ok && !procStart {
		pnew, t, err := ParseTokens(PNode{}, gnode, tokens, true)
		if err == .OK {

			switch val in pnew {
			case ParseNode:
				v := val
				v.value = name
				append(&pnode.next, v)
			case [2]ParseNode:
				// val[0] is only the *first* repetition unit (e.g. the
				// first STATEMENT of a CODE_ENTRY); val[1].next holds the
				// rest of them. All of it belongs to this one production,
				// so it all needs to end up under the single node we're
				// about to label - not as siblings of it one level up.
				v := val[0]
				v.value = name
				v.next = slice.clone_to_dynamic(v.next[:])
				for tail_child in val[1].next {
					append(&v.next, tail_child)
				}
				append(&pnode.next, v)
			}

			return pnode, t, .OK
		}
	}

	switch val in gnode.value {
	case ProductionName:
		assert(false, "should never happen")
	case Token:
		if match(val, tokens[0]) {
			append(&pnode.next, PNode{value = val})
			if len(gnode.nodes) == 0 {
				return pnode, tokens[1:], .OK
			}

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
				if len(gnode.nodes) == 0 do return p, t, .OK

				if gnode.endOfRepetition {
					p2, t2, err2 := ParseGnodeChildren({}, gnode, t)
					if err2 == .OK {
						return [2]PNode{Flatten_ParseResult(p), p2}, t2, .OK
					} else {
						return p, t, .OK
					}
				} else {
					if gnode.prodStart != nil {
						p2, t2, err2 := ParseGnodeChildren(PNode{}, gnode, t)
						if err == .OK {
							return [2]PNode{Flatten_ParseResult(p), p2}, t2, .OK
						}
					} else {
						p2, t2, err2 := ParseGnodeChildren(Flatten_ParseResult(p), gnode, t)
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
						return [2]PNode{Flatten_ParseResult(p), p2}, t2, .OK
					} else {
						return p, t, .OK
					}
				} else {
					p2, t2, err2 := ParseGnodeChildren(Flatten_ParseResult(p), gnode, tokens)
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
