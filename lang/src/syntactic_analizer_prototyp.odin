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
	value:   union {
		Token,
		DoArray,
		Deletable,
	} `json="value"`,
	nodes:   [dynamic]^GrammarNode `json="nodes"`,
	deleted: bool,
}
GNode :: GrammarNode

GNode_print :: proc(node: GrammarNode) {
	switch v in node.value {
	case Token:
		js, _ := json.marshal(v, json.Marshal_Options{pretty = true, use_enum_names = true})
		fmt.printf("%s\n", js)
	case Deletable:
		fmt.printf("deletable!\n")
	case DoArray:
		fmt.printf("DoArray:\n")
		for val, _ in node.value.(DoArray).value {
			GNode_print(val^)
		}
	}
	if len(node.nodes) > 0 {
		fmt.printf("Children:\n")
		for v, _ in node.nodes {
			GNode_print(v^)
		}
	}
}

GNode_Initialize :: proc(token: Token) -> GNode {
	return GNode{value = token, nodes = {}}
}

GNode_AppendNodeRef :: proc(node: ^GNode, appended: ^GNode) -> (int, GGraphError) {
	assert(node != nil, "nilptr")
	assert(appended != nil, "nilptr")

	_, ok := append(&node.nodes, appended)
	if ok != .None do return -1, .ALLOCATOR_ERROR

	return len(node.nodes) - 1, .OK
}

GNode_AppendNodeVal :: proc(node: ^GNode, appended: Token) -> (int, GGraphError) {
	assert(node != nil, "nilptr")

	ref, err := new(GNode)
	if err != .None do return -1, .ALLOCATOR_ERROR
	ref^ = GNode {
		value   = appended,
		nodes   = {},
		deleted = false,
	}

	_, ok := append(&node.nodes, ref)
	if ok != .None do return -1, .ALLOCATOR_ERROR

	return len(node.nodes) - 1, .OK
}

GNode_AppendNode :: proc {
	GNode_AppendNodeRef,
	GNode_AppendNodeVal,
}

GNode_Delete :: proc(node: ^GNode) {
	assert(node != nil)

	for v, i in node.nodes {
		if !v.deleted {
			v.deleted = true
			GNode_Delete(node.nodes[i])
			free(node.nodes[i])
		}
	}

	// switch v in node.value {
	// case Token:
	// break
	// case []^GrammarNode:
	// delete(node.value.([]^GrammarNode))
	// case Deletable:
	// break
	// }

	delete(node.nodes)
	clear(&node.nodes)
}

GrammarGraph :: struct {
	arr: [ProductionName]GNode,
}
GGraph :: GrammarGraph

UnrollProduction :: proc(prod: Production) -> GrammarNode {
	assert(len(prod) > 0)

	t := UnrollExpression(Expression(prod))

	// val, ok := t.value.(Deletable)
	// assert(val)
	// assert(ok)

	node: GNode
	val, ok := t.value.(Deletable)
	if ok && val {
		node.nodes = make([dynamic]^GNode, len(t.nodes))
		for v, i in t.nodes {
			node.nodes[i] = v
			_, ok := v.value.(Deletable)
			assert(!ok)
		}
	} else {
		// node.value.(DoArray).value = make([]^GrammarNode, 1)
		node.value = DoArray {
			skippable = false,
			value     = make([]^GNode, 1),
		}

		node.value.(DoArray).value[0] = new(GNode)
		node.value.(DoArray).value[0]^ = t

		// node.nodes = make([dynamic]^GNode, 1)
		// node.nodes[0] = new(GNode)
		// node.nodes[0]^ = t
	}

	// assert(false, "not implemented")
	// return GNode{}

	return node
}

UnrollExpression :: proc(expr: Expression) -> GrammarNode {
	assert(len(expr) >= 1, "Empty expression")

	if len(expr) > 1 {

		sum := 0

		nodes := make([]GNode, len(expr))
		for _, i in expr {
			nodes[i] = UnrollAlternative(expr[i])
		}

		for v, i in nodes {
			if _, ok := v.value.(Deletable); ok {
				sum += len(v.nodes)
			} else {
				sum += 1
			}
		}

		node: GNode = GNode {
			// value   = Deletable(true),
			value = DoArray{skippable = true, value = make([]^GNode, sum)},
			// nodes   = make([dynamic]^GrammarNode, len(expr)),
			nodes = {},
			deleted = false,
		}

		// for i in 0 ..< len(node.value.(DoArray).value) {
		idx := 0
		for v, i in nodes {
			if _, ok := v.value.(Deletable); ok {
				for w, j in v.nodes {
					node.value.(DoArray).value[idx] = w
					idx += 1
				}
			} else {
				node.value.(DoArray).value[idx] = &nodes[i]
				idx += 1
			}
		}

		// for _, i in expr {
		// 	ptr := new(GNode)
		// 	ptr^ = UnrollAlternative(expr[i])
		// 	node.value.(DoArray).value[i] = ptr
		// }

		// assert(false, "not implemented")
		return node

	} else {
		return UnrollAlternative(expr[0])
	}
}

// UnrollAlternative :: proc(alt: Alternative) -> GrammarNode {
// return {}
// }
UnrollAlternative :: proc(alt: Alternative) -> GrammarNode {

	assert(len(alt) >= 1, "Empty alternative")

	node: GNode

	if len(alt) == 1 {
		node = UnrollTerm(alt[0])
		_, ok := node.value.(Deletable)
		assert(!ok)
		return node
	}

	nodes := make([]GNode, len(alt))
	for v, i in alt {
		nodes[i] = UnrollTerm(alt[i])
		append(&nodes[i].nodes, &nodes[(i + 1) % len(nodes)])
	}

	node = GNode {
		deleted = false,
		value = DoArray{skippable = true, value = make([]^GNode, 1)},
	}
	node.value.(DoArray).value[0] = &nodes[0]

	return node


	// assert(len(alt) >= 1, "Empty alternative")

	// node := GNode {
	// 	deleted = false,
	// 	value = DoArray{skippable = false, value = make([]^GNode, len(alt))},
	// }

	// nodes := make([]GNode, len(alt))
	// for v, i in alt {
	// 	nodes[i] = UnrollTerm(v)
	// 	node.value.(DoArray).value[i] = &nodes[i]
	// }

	// // assert(false, "not implemented")
	// // return {}

	// return node
}

UnrollTerm :: proc(term: Term) -> GrammarNode {

	node: GNode

	switch v in term {
	case ProductionName:
		if prod, ok := UnrolledProductions[v].?; !ok {
			UnrolledProductions[v] = UnrollProduction(Productions[v])
			prodd, okk := UnrolledProductions[v].?
			assert(okk)
			node = prodd
		} else {
			node = prod
		}
		// node = UnrollProduction(Productions[v])
		_, ok := node.value.(Deletable)
		assert(!ok)
	case Token:
		node = GNode {
			value   = v,
			nodes   = {},
			deleted = false,
		}
	case Group:
		node = UnrollGroup(v)
		_, ok := node.value.(Deletable)
		assert(ok)
	case Option:
		opt := UnrollOption(v)
		_, ok := opt.value.(Deletable)
		assert(ok)


	case Repetition:
		node = UnrollRepetition(v)
		_, ok := node.value.(Deletable)
		assert(!ok)

	}

	// assert(false, "not implemented")
	return node
}

UnrollGroup :: proc(group: Group) -> GrammarNode {
	assert(len(group) >= 1, "Empty group")

	exs := make([]GNode, len(group))
	sum := 0

	for v, i in group {
		exs[i] = UnrollExpression(group[i])
		if _, ok := exs[i].value.(Deletable); ok {
			sum += len(exs[i].nodes)
		} else {
			sum += 1
		}
	}

	node := GNode {
		deleted = false,
		value = DoArray{skippable = false, value = make([]^GNode, sum)},
		nodes = {},
	}

	idx := 0
	for v, i in exs {
		if _, ok := v.value.(Deletable); ok {
			for w, _ in v.nodes {
				node.value.(DoArray).value[idx] = w
				idx += 1
			}
		} else {
			node.value.(DoArray).value[idx] = &exs[i]
			idx += 1
		}

	}

	return node
}

UnrollOption :: proc(opt: Option) -> GrammarNode {

	assert(len(opt) == 1, "Incorrect option")

	temp := UnrollExpression(Expression(opt[0]))

	node: GNode

	switch v in temp.value {
	case Token:
		node = {
			deleted = false,
			value = DoArray{skippable = true, value = make([]^GNode, 1)},
		}
		node.value.(DoArray).value[0]^ = temp
	case Deletable:
		node = {
			deleted = false,
			value = DoArray{skippable = true, value = make([]^GNode, len(temp.nodes))},
		}
		for v, i in temp.nodes {
			node.value.(DoArray).value[i] = v
		}
	case DoArray:
		// node = {
		// 	deleted = false,
		// 	value = DoArray{skippable = true, value = make([]^GNode, 1)},
		// }
		node = temp
		assert(temp.nodes == nil)
	}

	return node
}

UnrollRepetition :: proc(rep: Repetition) -> GrammarNode {
	assert(len(rep) >= 1, "Empty repetition")

	node: GNode

	nodes := make([]GNode, len(rep))
	for v, i in rep {
		nodes[i] = UnrollExpression(rep[i])
		append(&nodes[i].nodes, &nodes[(i + 1) % len(nodes)])
	}

	node = GNode {
		deleted = false,
		value = DoArray{skippable = true, value = make([]^GNode, 1)},
	}
	node.value.(DoArray).value[0] = &nodes[0]

	return node
}
