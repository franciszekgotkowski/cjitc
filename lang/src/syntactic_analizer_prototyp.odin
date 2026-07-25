package langlang

import "core:fmt"
import "core:mem"

GGraphError :: enum {
	OK,
	ALLOCATOR_ERROR,
}

UnrolledProduction :: []GrammarNode

GrammarNode :: struct {
	value:   union {
		Token,
		UnrolledProduction,
	} `json="value"`,
	nodes:   [dynamic]^GrammarNode `json="nodes"`,
	deleted: bool,
}
GNode :: GrammarNode

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

	switch v in node.value {
	case Token:
		break
	case UnrolledProduction:
		delete(node.value.(UnrolledProduction))
	}

	delete(node.nodes)
	clear(&node.nodes)
}

GrammarGraph :: struct {
	arr: [ProductionName]GNode,
}
GGraph :: GrammarGraph
