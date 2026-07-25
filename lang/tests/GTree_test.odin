package tests

import lang "../src"
import "core:testing"

Token :: lang.Token

GNode :: lang.GNode
GNode_Initialize :: lang.GNode_Initialize
GNode_AppendNode :: lang.GNode_AppendNode
GNode_Delete :: lang.GNode_Delete

GTree_Error :: lang.GGraphError

@(test)
GNode_Delete_test :: proc(t: ^testing.T) {
	root := GNode_Initialize(Token{type = .KEYWORD, kind = lang.Keyword.INT})

	exp(t, len(root.nodes) == 0)
	GNode_Delete(&root)
	exp(t, len(root.nodes) == 0)

	err: GTree_Error
	_, err = GNode_AppendNode(&root, Token{type = .KEYWORD, kind = lang.Keyword.INT})
	exp(t, err == .OK)
	_, err = GNode_AppendNode(&root, Token{type = .KEYWORD, kind = lang.Keyword.FLOAT})
	exp(t, err == .OK)
	_, err = GNode_AppendNode(root.nodes[0], Token{type = .KEYWORD, kind = lang.Keyword.FLOAT})
	exp(t, err == .OK)
	_, err = GNode_AppendNode(&root, Token{type = .KEYWORD, kind = lang.Keyword.CHAR})
	exp(t, err == .OK)
	_, err = GNode_AppendNode(root.nodes[0], Token{type = .KEYWORD, kind = lang.Keyword.CHAR})
	exp(t, err == .OK)
	_, err = GNode_AppendNode(root.nodes[1], Token{type = .KEYWORD, kind = lang.Keyword.CHAR})
	exp(t, err == .OK)

	ptr := new(GNode)
	exp(t, ptr != nil)
	vals := make(lang.UnrolledProduction, 5)

	ptr^ = GNode {
		value   = vals,
		nodes   = {},
		deleted = false,
	}
	_, err = GNode_AppendNode(&root, ptr)
	exp(t, err == .OK)
	_, err = GNode_AppendNode(root.nodes[0], ptr)
	exp(t, err == .OK)
	_, err = GNode_AppendNode(root.nodes[0].nodes[1], ptr)
	exp(t, err == .OK)
	_, err = GNode_AppendNode(root.nodes[1].nodes[0], ptr)
	exp(t, err == .OK)
	_, err = GNode_AppendNode(root.nodes[2], ptr)
	exp(t, err == .OK)

	_, err = GNode_AppendNode(ptr, root.nodes[2])
	exp(t, err == .OK)


	GNode_Delete(&root)
	exp(t, len(root.nodes) == 0)

}
