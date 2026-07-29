package langlang

import "core:encoding/json"
import "core:fmt"

ParseError :: enum {
	OK,
	ALLOCATOR_ERROR,
	COULD_NOT_MATCH,
	LOGICAL_ERROR,
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

ParseProduction :: proc(
	productionName: ProductionName,
	tokens: []Token,
	i: int,
) -> (
	PNode,
	int,
	ParseError,
) {
	assert(tokens != nil, "nilptr")

	ConsumeGNode :: proc(
		pnode: PNode,
		gnode: ^GNode,
		tokens: []Token,
		i: int,
	) -> (
		PNode,
		int,
		ParseError,
	) {
		assert(gnode != nil, "nilptr")
		assert(tokens != nil, "nilptr")
		assert(i >= 0)

		pnode := pnode
		i := i

		if name, ok := gnode.prodStart.?; ok {
			p, i, err := ParseProduction(name, tokens, i)
			if err == .OK {
				append(&pnode.next, p)

				if len(gnode.nodes) == 0 {
					return pnode, i, .OK
				}
				assert(len(gnode.nodes) > 0)

				found := false
				for v, ii in gnode.nodes {
					p, j, err := ConsumeGNode(pnode, gnode.nodes[ii], tokens, i + 1)
					if err == .OK {
						// append(&pnode.next, p)
						pnode = p
						i = j
						found = true
					}
				}
				if !found {
					return {}, -1, .COULD_NOT_MATCH
				}

				return pnode, i, .OK
			} else {
				return {}, -1, .COULD_NOT_MATCH
			}
		}


		switch val in gnode.value {
		case Token:
			if !match(val, tokens[i]) {
				{
					json, _ := json.marshal(val, json.Marshal_Options{use_enum_names = true})
					fmt.printf("Could not match token:\t%s\n", json)
				}
				return {}, -1, .COULD_NOT_MATCH
			}
			{
				json, _ := json.marshal(val, json.Marshal_Options{use_enum_names = true})
				fmt.printf("Matching token:\t%s\n", json)
			}
			append(&pnode.next, PNode{value = val})
			if len(gnode.nodes) == 0 {
				return pnode, i, .OK
			}

			for v, ii in gnode.nodes {
				p, j, err := ConsumeGNode(pnode, gnode.nodes[ii], tokens, i + 1)
				if err == .OK {
					return p, j, .OK
				}
			}
			if gnode.endOfRepetition {
				return pnode, i, .OK
			}

			return {}, -1, .COULD_NOT_MATCH
		case DoArray:
			found := false
			loop: for v, ii in val.value {
				p, j, err := ConsumeGNode(pnode, val.value[ii], tokens, i + 1)
				if err == .OK {
					append(&pnode.next, p)
					// pnode = p
					i = j
					found = true
					break loop
				}
			}
			if !found && !val.skippable {
				return {}, -1, .COULD_NOT_MATCH
			}
			assert(found || val.skippable)
			if len(gnode.nodes) == 0 {
				if found {
					return pnode, i, .OK
				} else {
					return {}, -1, .COULD_NOT_MATCH
				}
			}
			for v, ii in gnode.nodes {
				p, j, err := ConsumeGNode(pnode, gnode.nodes[ii], tokens, i + 1)
				if err == .OK {
					return p, j, .OK
				}
			}
			return {}, -1, .COULD_NOT_MATCH
		}

		assert(false, "should never happen")
		return {}, -1, .LOGICAL_ERROR
	}

	i := i
	newp := PNode {
		value = productionName,
	}

	gprod, ok := UnrolledProductions[productionName].?

	found := false
	switch val in gprod.value {
	case DoArray:
		loop: for v, ii in val.value {
			p, j, err := ConsumeGNode(newp, val.value[ii], tokens, i)
			if err == .OK {
				found = true
				newp = p
				i = j
				break loop
			}
		}
	case Token:
		if !match(val, tokens[i]) {
			{
				json, _ := json.marshal(val, json.Marshal_Options{use_enum_names = true})
				fmt.printf("Could not match token:\t%s\n", json)
			}
			return {}, -1, .COULD_NOT_MATCH
		} else {
			found = true
			append(&newp.next, PNode{value = val})
			json, _ := json.marshal(val, json.Marshal_Options{use_enum_names = true})
			fmt.printf("Matching token:\t%s\n", json)
		}
	}

	if found {
		return newp, i, .OK
	} else {
		return {}, -1, .COULD_NOT_MATCH
	}
}
