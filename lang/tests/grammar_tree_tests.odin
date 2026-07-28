package tests

import lang "../src"

Token :: lang.Token
GNode :: lang.GNode
DoArray :: lang.DoArray
GrammarNode_SearchInAddArray :: lang.GrammarNode_SearchInAddArray
GrammarNode_MatchToken :: lang.GrammarNode_MatchToken

Keyword :: lang.Keyword
Delimiter :: lang.Delimiter
Operator :: lang.Operator
Literal :: lang.Literal
TokenType :: lang.TokenType

Production :: lang.Production
Expression :: lang.Expression
Alternative :: lang.Alternative
Term :: lang.Term
Group :: lang.Group
Option :: lang.Option
Repetition :: lang.Repetition
ProductionName :: lang.ProductionName

Unroll_Production :: lang.Unroll_Production
Unroll_Expression :: lang.Unroll_Expression
Unroll_Alternative :: lang.Unroll_Alternative
Unroll_Term :: lang.Unroll_Term
Unroll_Group :: lang.Unroll_Group
Unroll_Option :: lang.Unroll_Option
Unroll_Repetition :: lang.Unroll_Repetition

match :: lang.match
Token_Match :: lang.Token_Match

import "core:testing"

@(test)
test_search_in_add_array_simple :: proc(t: ^testing.T) {
	tok := Token {
		type = .KEYWORD,
		kind = Keyword.INT,
	}

	leaf := GNode {
		value = tok,
	}

	root := GNode {
		value = DoArray{value = []^GNode{&leaf}},
	}

	ptr := GrammarNode_SearchInAddArray(&root, tok)

	testing.expect(t, ptr != nil)
	testing.expect(t, ptr == &leaf)

	free_all()
}

@(test)
test_search_in_add_array_not_found :: proc(t: ^testing.T) {
	leaf := GNode {
		value = Token{type = .KEYWORD, kind = Keyword.FLOAT},
	}

	root := GNode {
		value = DoArray{value = []^GNode{&leaf}},
	}

	ptr := GrammarNode_SearchInAddArray(&root, Token{type = .KEYWORD, kind = Keyword.INT})

	testing.expect(t, ptr == nil)
	free_all()
}

@(test)
test_search_in_add_array_recursive :: proc(t: ^testing.T) {
	target := GNode {
		value = Token{type = .KEYWORD, kind = Keyword.INT},
	}

	inner := GNode {
		value = DoArray{value = []^GNode{&target}},
	}

	outer := GNode {
		value = DoArray{value = []^GNode{&inner}},
	}

	ptr := GrammarNode_SearchInAddArray(&outer, Token{type = .KEYWORD, kind = Keyword.INT})

	testing.expect(t, ptr == &target)
	free_all()
}

@(test)
test_match_token_direct :: proc(t: ^testing.T) {
	child := GNode {
		value = Token{type = .KEYWORD, kind = Keyword.INT},
	}

	root := GNode{}
	append(&root.nodes, &child)

	ptr, err := GrammarNode_MatchToken(&root, Token{type = .KEYWORD, kind = Keyword.INT})

	testing.expect(t, err == .OK)
	testing.expect(t, ptr == &child)
	free_all()
}

@(test)
test_match_token_inside_doarray :: proc(t: ^testing.T) {
	tok := GNode {
		value = Token{type = .KEYWORD, kind = Keyword.INT},
	}

	array := GNode {
		value = DoArray{value = []^GNode{&tok}},
	}

	root := GNode{}
	append(&root.nodes, &array)

	ptr, err := GrammarNode_MatchToken(&root, Token{type = .KEYWORD, kind = Keyword.INT})

	testing.expect(t, err == .OK)
	testing.expect(t, ptr == &tok)
	free_all()
}

@(test)
test_match_token_failure :: proc(t: ^testing.T) {
	root := GNode{}

	_, err := GrammarNode_MatchToken(&root, Token{type = .KEYWORD, kind = Keyword.INT})

	testing.expect(t, err == .COULD_NOT_MATCH)
	free_all()
}

@(test)
test_unroll_term_token_gpt :: proc(t: ^testing.T) {
	tok := Token {
		type = .KEYWORD,
		kind = Keyword.INT,
	}

	node := Unroll_Term(tok)

	_, ok := node.value.(Token)

	testing.expect(t, ok)
	testing.expect(t, match(node.value.(Token), tok))
	free_all()
}

@(test)
test_unroll_term_production :: proc(t: ^testing.T) {
	lang.UnrolledProductions = {}

	node := Unroll_Term(ProductionName.DECIMAL_TYPE)

	testing.expect(t, node.prodStart == .DECIMAL_TYPE)
	free_all()
}

@(test)
test_unroll_expression_single :: proc(t: ^testing.T) {
	expr := Expression{Alternative{Token{type = .KEYWORD, kind = Keyword.INT}}}

	node := Unroll_Expression(expr)

	_, ok := node.value.(Token)

	testing.expect(t, ok)
	free_all()
}

@(test)
test_unroll_expression_multiple :: proc(t: ^testing.T) {
	expr := Expression {
		Alternative{Token{type = .KEYWORD, kind = Keyword.INT}},
		Alternative{Token{type = .KEYWORD, kind = Keyword.FLOAT}},
	}

	node := Unroll_Expression(expr)

	arr, ok := node.value.(DoArray)

	testing.expect(t, ok)
	testing.expect(t, len(arr.value) == 2)
	free_all()
}

@(test)
test_unroll_alternative_chain :: proc(t: ^testing.T) {
	alt := Alternative {
		Token{type = .KEYWORD, kind = Keyword.INT},
		Token{type = .IDENTIFIER},
		Token{type = .DELIMITER, kind = Delimiter.SEMICOLUMN},
	}

	node := Unroll_Alternative(alt)

	arr := node.value.(DoArray)

	testing.expect(t, len(arr.value) == 3)

	first := arr.value[0]
	second := arr.value[1]

	testing.expect(t, len(first.nodes) == 1)
	testing.expect(t, first.nodes[0] == second)
	free_all()
}

@(test)
test_unroll_group_skippable :: proc(t: ^testing.T) {
	grp := Group {
		Expression{Alternative{Token{type = .KEYWORD, kind = Keyword.INT}}},
		Expression{Alternative{Token{type = .KEYWORD, kind = Keyword.FLOAT}}},
	}

	node := Unroll_Group(grp)

	arr := node.value.(DoArray)

	testing.expect(t, arr.skippable)
	testing.expect(t, len(arr.value) == 2)
	free_all()
}

@(test)
test_unroll_option :: proc(t: ^testing.T) {
	opt := Option{Expression{Alternative{Token{type = .KEYWORD, kind = Keyword.INT}}}}

	node := Unroll_Option(opt)

	arr := node.value.(DoArray)

	testing.expect(t, arr.skippable)
	testing.expect(t, len(arr.value) == 1)
	free_all()
}

@(test)
test_unroll_repetition :: proc(t: ^testing.T) {
	rep := Repetition {
		Expression{Alternative{Token{type = .KEYWORD, kind = Keyword.INT}}},
		Expression{Alternative{Token{type = .KEYWORD, kind = Keyword.FLOAT}}},
	}

	node := Unroll_Repetition(rep)

	arr := node.value.(DoArray)

	testing.expect(t, len(arr.value) == 2)

	last := arr.value[len(arr.value) - 1]

	testing.expect(t, last.endOfRepetition)
	free_all()
}
