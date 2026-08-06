package langlang

GGraphError :: enum {
	OK,
	ALLOCATOR_ERROR,
}

DoArray :: struct {
	value:     []^GrammarNode `json="values"`,
	skippable: bool `json="skippable"`,
}
Deletable :: bool

PrepareGrammarGraph :: proc() {
	p := &UnrolledProductions
	for v, i in ProductionName {
		UnrolledProductions[v] = Unroll_Production(Productions[v], v)
	}
	return

	// DFSProcedureLinkind :: proc(gnode: ^GNode) {
	// 	if gnode.visited do return

	// 	gnode.visited = true
	// 	if v, ok := gnode.value.(ProductionName); ok {
	// 		gn, ok := UnrolledProductions[v].?
	// 		assert(ok)
	// 		if val, ok := gn.value.(ProductionName); ok do DFSProcedureLinkind(&UnrolledProductions[v].?)
	// 		gnode^ = gn
	// 	}
	// 	for _, i in gnode.nodes {
	// 		DFSProcedureLinkind(gnode.nodes[i])
	// 	}
	// 	if _, ok := gnode.value.(DoArray); ok {
	// 		for _, i in gnode.value.(DoArray).value {
	// 			DFSProcedureLinkind(gnode.value.(DoArray).value[i])
	// 		}
	// 	}
	// }

	// for _, i in UnrolledProductions {
	// 	DFSProcedureLinkind(&UnrolledProductions[i].?)
	// }

}

GrammarNode :: struct {
	value:           union {
		Token,
		DoArray,
		ProductionName,
	} `json="value"`,
	nodes:           [dynamic]^GrammarNode `json="nodes"`,
	endOfRepetition: bool `json="end of repetition"`,
	prodStart:       Maybe(ProductionName) `json="Production start:"`,
	visited:         bool,
}
GNode :: GrammarNode

GrammarNode_SearchInAddArray :: proc(node: ^GNode, token: Token) -> ^GNode {
	_, ok := node.value.(DoArray)
	if !ok do return nil

	ret: ^GNode

	loop: for v, i in node.value.(DoArray).value {
		switch val in v.value {
		case DoArray:
			t := GrammarNode_SearchInAddArray(node.value.(DoArray).value[i], token)
			if t != nil {
				ret = t
				break loop
			}
		case Token:
			if match(v.value.(Token), token) {
				t := node.value.(DoArray).value[i]
				if t != nil {
					ret = t
					break loop
				}
			}
		case ProductionName:
			assert(false, "should never happen")
		}

	}

	return ret
}

GrammarNode_MatchToken :: proc(node: ^GNode, token: Token) -> (^GNode, ParseError) {
	ret: ^GNode

	loop: for v, i in node.nodes {
		switch val in v.value {
		case Token:
			if match(token, val) {
				ret = node.nodes[i]
				break loop
			}
		case DoArray:
			if ptr := GrammarNode_SearchInAddArray(v, token); ptr != nil {
				ret = ptr
				break loop
			}
		case ProductionName:
			assert(false, "should never happen")
		}

	}

	if ret == nil {
		return ret, .COULD_NOT_MATCH
	}
	return ret, .OK
}

Unroll_Production :: proc(prod: Production, name: ProductionName) -> GNode {
	assert(prod != nil)
	assert(len(prod) > 0)

	node := Unroll_Expression(Expression(prod))
	node.prodStart = name

	return node
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
		if i != len(alt) - 1 {
			append(&arr[i].nodes, &arr[(i + 1) % len(arr)])
		}
	}

	node := GNode {
		value = DoArray{skippable = false, value = make([]^GrammarNode, 1)},
	}
	node.value.(DoArray).value[0] = &arr[0]

	return node
}

Unroll_Term :: proc(term: Term) -> GNode {

	node: GNode

	switch v in term {
	case ProductionName:
		arr := make([]^GrammarNode, 1)
		arr[0] = &UnrolledProductions[v]
		node = {
			value = DoArray{value = arr},
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
}

Unroll_Repetition :: proc(rep: Repetition) -> GNode {
	assert(rep != nil)
	assert(len(rep) > 0)

	arr := make([]GNode, len(rep))

	for v, i in rep {
		arr[i] = Unroll_Expression(v)
		append(&arr[i].nodes, &arr[(i + 1) % len(arr)])
	}
	arr[len(arr) - 1].endOfRepetition = true

	node := GNode {
		value = DoArray{skippable = true, value = make([]^GrammarNode, 1)},
	}
	node.value.(DoArray).value[0] = &arr[0]

	return node
}
