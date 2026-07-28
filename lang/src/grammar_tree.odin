package langlang

import "core:encoding/json"
import "core:fmt"

GGraphError :: enum {
	OK,
	ALLOCATOR_ERROR,
}

DoArray :: struct {
	value:     []^GrammarNode `json="values"`,
	skippable: bool `json="skippable"`,
}
Deletable :: bool

GrammarNode :: struct {
	value:    union {
		Token,
		DoArray,
	} `json="value"`,
	nodes:    [dynamic]^GrammarNode `json="nodes"`,
	printed:  bool,
	consumed: bool,
}
GNode :: GrammarNode

GNode_Print :: GrammarNode_Print

@(private = "file")
GrammarNode_SearchInAddArray :: proc(node: ^GNode, token: Token) -> ^GNode {
	_, ok := node.value.(DoArray)
	if !ok do return nil

	ret: ^GNode
	for v, i in node.value.(DoArray).value {
		switch val in v.value {
		case DoArray:
			ret = GrammarNode_SearchInAddArray(node.value.(DoArray).value[i], token)
			break
		case Token:
			if match(v.value.(Token), token) {
				ret = node
				break
			}
		}

	}

	return ret
}

GrammarNode_MatchToken :: proc(node: ^GNode, token: Token) -> (^GNode, ParseError) {
	_, ok := node.value.(Token)
	assert(ok)

	ret: ^GNode

	for v, i in node.nodes {
		switch val in v.value {
		case Token:
			if match(token, val) {
				ret = node.nodes[i]
				break
			}
		case DoArray:
			if ptr := GrammarNode_SearchInAddArray(v, token); ptr != nil {
				ret = ptr
				break
			}
		}

	}

	if ret == nil {
		return ret, .COULD_NOT_MATCH
	}
	return ret, .OK
}

// Prints out recursively contents of GNode's
// TODO: implement setting node.printed = false
GrammarNode_Print :: proc(node: ^GNode) {
	if node.printed {
		return
	}
	node.printed = true

	switch val in node.value {
	case Token:
		js, _ := json.marshal(val, json.Marshal_Options{pretty = true, use_enum_names = true})
		fmt.printf("%s\n", js)
	case DoArray:
		fmt.printf("DoArray:\n")
		for v, _ in node.value.(DoArray).value {
			GNode_Print(v)
		}
	}
	if len(node.nodes) > 0 {
		fmt.printf("Next:\n")
		for v, _ in node.nodes {
			GNode_Print(v)
		}
		fmt.printf("\n")
	}
}

Unroll_Production :: proc(prod: Production) -> GNode {
	assert(prod != nil)
	assert(len(prod) > 0)

	node: GNode
	t := Unroll_Expression(Expression(prod))

	node = t
	return node

	// switch val in t.value {
	// case Token:
	// 	node = t
	// case DoArray:

	// }
}

Unroll_Expression :: proc(expr: Expression) -> GNode {
	assert(expr != nil)
	assert(len(expr) > 0)

	node: GNode

	if len(expr) == 1 {
		return Unroll_Alternative(expr[0])
	}

	arr := make([]GNode, len(expr))
	for v, i in expr {
		arr[i] = Unroll_Alternative(v)
	}
	node.value = DoArray {
		skippable = false,
		value     = make([]^GNode, len(expr)),
	}
	for _, i in arr {
		node.value.(DoArray).value[i] = &arr[i]
	}

	return node
}

Unroll_Alternative :: proc(alt: Alternative) -> GNode {
	assert(alt != nil)
	assert(len(alt) > 0)

	if len(alt) == 1 {
		return Unroll_Term(alt[0])
	}

	arr := make([]GNode, len(alt))

	for v, i in alt {
		arr[i] = Unroll_Term(v)
		if i != len(alt) - 2 {
			append(&arr[i].nodes, &arr[(i + 1) % len(arr)])
		}
	}

	node := GNode {
		value = DoArray{skippable = false, value = make([]^GrammarNode, len(arr))},
	}
	for v, i in arr {
		node.value.(DoArray).value[i] = &arr[i]
	}

	return node
}

Unroll_Term :: proc(term: Term) -> GNode {

	node: GNode

	switch v in term {
	case ProductionName:
		if val, ok := UnrolledProductions[v].?; ok {
			node = val
		} else {
			UnrolledProductions[v] = Unroll_Production(Productions[v])
			val, ok := UnrolledProductions[v].?
			assert(ok)
			node = val
		}
	case Token:
		node = {
			value = v,
		}
	case Group:
		node = Unroll_Group(v)
	case Option:
		node = Unroll_Option(v)
	case Repetition:
		node = Unroll_Repetition(v)
	}

	return node
}

Unroll_Group :: proc(group: Group) -> GNode {
	assert(group != nil)
	assert(len(group) > 0)


	node: GNode

	if len(group) == 1 {
		return Unroll_Expression(group[0])
	}

	arr := make([]GNode, len(group))
	for v, i in group {
		arr[i] = Unroll_Expression(v)
	}
	node.value = DoArray {
		skippable = true,
		value     = make([]^GNode, len(group)),
	}
	for _, i in arr {
		node.value.(DoArray).value[i] = &arr[i]
	}

	return node

	// assert(false, "not implemented")
	// return {}
}

Unroll_Option :: proc(opt: Option) -> GNode {
	assert(opt != nil)
	assert(len(opt) == 1)


	node: GNode

	arr := make([]GNode, len(opt))
	for v, i in opt {
		arr[i] = Unroll_Expression(v)
	}
	node.value = DoArray {
		skippable = true,
		value     = make([]^GNode, len(opt)),
	}
	for _, i in arr {
		node.value.(DoArray).value[i] = &arr[i]
	}

	return node

	// assert(false, "not implemented")
	// return {}
}

Unroll_Repetition :: proc(rep: Repetition) -> GNode {
	assert(rep != nil)
	assert(len(rep) > 0)

	arr := make([]GNode, len(rep))

	for v, i in rep {
		arr[i] = Unroll_Expression(v)
		append(&arr[i].nodes, &arr[(i + 1) % len(arr)])
	}

	node := GNode {
		value = DoArray{skippable = false, value = make([]^GrammarNode, len(arr))},
	}
	for v, i in arr {
		node.value.(DoArray).value[i] = &arr[i]
	}

	return node
}
