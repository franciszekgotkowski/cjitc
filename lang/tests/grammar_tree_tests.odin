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

// ---------------------------------------------------------------------------
// PrepareGrammarGraph over the real Productions table, focused on the
// grammar recently added to grammar_constants.odin: FUNCTION_DECLARATION,
// MEMBER_ACCESS_EXPRESSION / MEMBER_ACCESS_PTR_EXPRESSION, PREFIX_OPERATORS
// / POSTFIX_OPERATORS, and the reworked UNARY_EXPRESSIONS.
//
// These check the GNode *graph shape* (prodStart, alternative counts,
// which ProductionName wrapper points at which slot) - i.e. that the
// grammar as written in grammar_constants.odin got built the way it reads,
// as opposed to parse_tree_tests.odin which checks that real token
// sequences parse into a correct ParseNode tree.
// ---------------------------------------------------------------------------

@(test)
test_grammar_graph_function_declaration_prod_start :: proc(t: ^testing.T) {
	PrepareGrammarGraph()

	node := lang.UnrolledProductions[.FUNCTION_DECLARATION]
	name, ok := node.prodStart.?
	testing.expect(t, ok)
	testing.expect(t, name == .FUNCTION_DECLARATION)
	free_all()
}

@(test)
test_grammar_graph_decls_has_three_alternatives_including_function_declaration :: proc(t: ^testing.T) {
	PrepareGrammarGraph()

	decls := lang.UnrolledProductions[.DECLS]
	arr, ok := decls.value.(DoArray)
	testing.expect(t, ok)
	testing.expect_value(t, len(arr.value), len(lang.Productions[.DECLS]))
	testing.expect_value(t, len(arr.value), 3)

	// third alternative should be the wrapper pointing at
	// UnrolledProductions[.FUNCTION_DECLARATION]
	third := arr.value[2]
	third_arr, third_ok := third.value.(DoArray)
	testing.expect(t, third_ok)
	testing.expect_value(t, len(third_arr.value), 1)
	testing.expect(t, third_arr.value[0] == &lang.UnrolledProductions[.FUNCTION_DECLARATION])
	free_all()
}

@(test)
test_grammar_graph_expression_includes_member_access_alternatives :: proc(t: ^testing.T) {
	PrepareGrammarGraph()

	expr := lang.UnrolledProductions[.EXPRESSION]
	arr, ok := expr.value.(DoArray)
	testing.expect(t, ok)
	testing.expect_value(t, len(arr.value), len(lang.Productions[.EXPRESSION]))
	testing.expect_value(t, len(arr.value), 6)

	member_access := arr.value[4]
	member_access_arr, ma_ok := member_access.value.(DoArray)
	testing.expect(t, ma_ok)
	testing.expect(t, member_access_arr.value[0] == &lang.UnrolledProductions[.MEMBER_ACCESS_EXPRESSION])

	member_access_ptr := arr.value[5]
	member_access_ptr_arr, map_ok := member_access_ptr.value.(DoArray)
	testing.expect(t, map_ok)
	testing.expect(t, member_access_ptr_arr.value[0] == &lang.UnrolledProductions[.MEMBER_ACCESS_PTR_EXPRESSION])
	free_all()
}

@(test)
test_grammar_graph_member_access_expression_is_three_term_chain :: proc(t: ^testing.T) {
	PrepareGrammarGraph()

	node := lang.UnrolledProductions[.MEMBER_ACCESS_EXPRESSION]
	name, ok := node.prodStart.?
	testing.expect(t, ok && name == .MEMBER_ACCESS_EXPRESSION)

	// IDENTIFIER "." IDENTIFIER: a single entry point chained through
	// .nodes, same shape as any other multi-term Alternative.
	arr, arr_ok := node.value.(DoArray)
	testing.expect(t, arr_ok)
	testing.expect_value(t, len(arr.value), 1)

	first := arr.value[0]
	_, first_is_identifier := first.value.(Token)
	testing.expect(t, first_is_identifier)
	testing.expect_value(t, len(first.nodes), 1)
	if len(first.nodes) != 1 do return

	dot := first.nodes[0]
	dot_tok, dot_ok := dot.value.(Token)
	testing.expect(t, dot_ok && dot_tok.type == .OPERATOR && dot_tok.kind == Operator.DOT)
	testing.expect_value(t, len(dot.nodes), 1)
	free_all()
}

@(test)
test_grammar_graph_member_access_ptr_expression_uses_right_arrow :: proc(t: ^testing.T) {
	PrepareGrammarGraph()

	node := lang.UnrolledProductions[.MEMBER_ACCESS_PTR_EXPRESSION]
	arr, arr_ok := node.value.(DoArray)
	testing.expect(t, arr_ok)

	first := arr.value[0]
	testing.expect_value(t, len(first.nodes), 1)
	if len(first.nodes) != 1 do return

	arrow := first.nodes[0]
	arrow_tok, arrow_ok := arrow.value.(Token)
	testing.expect(t, arrow_ok && arrow_tok.type == .OPERATOR && arrow_tok.kind == Operator.RIGHT_ARROW)
	free_all()
}

@(test)
test_grammar_graph_prefix_and_postfix_operator_counts :: proc(t: ^testing.T) {
	PrepareGrammarGraph()

	prefix := lang.UnrolledProductions[.PREFIX_OPERATORS]
	prefix_arr, prefix_ok := prefix.value.(DoArray)
	testing.expect(t, prefix_ok)
	testing.expect_value(t, len(prefix_arr.value), len(lang.Productions[.PREFIX_OPERATORS]))

	postfix := lang.UnrolledProductions[.POSTFIX_OPERATORS]
	postfix_arr, postfix_ok := postfix.value.(DoArray)
	testing.expect(t, postfix_ok)
	testing.expect_value(t, len(postfix_arr.value), len(lang.Productions[.POSTFIX_OPERATORS]))
	free_all()
}

@(test)
test_grammar_graph_unary_expressions_has_three_alternatives :: proc(t: ^testing.T) {
	PrepareGrammarGraph()

	node := lang.UnrolledProductions[.UNARY_EXPRESSIONS]
	name, ok := node.prodStart.?
	testing.expect(t, ok && name == .UNARY_EXPRESSIONS)

	arr, arr_ok := node.value.(DoArray)
	testing.expect(t, arr_ok)
	testing.expect_value(t, len(arr.value), len(lang.Productions[.UNARY_EXPRESSIONS]))
	testing.expect_value(t, len(arr.value), 3)

	// first alternative is a 2-term Alternative (PREFIX_OPERATORS, Group),
	// so arr.value[0] is that alternative's own single entry point, whose
	// one DoArray element is the actual PREFIX_OPERATORS-wrapper term,
	// chained via .nodes to the Group term.
	first_alt := arr.value[0]
	first_alt_arr, first_alt_ok := first_alt.value.(DoArray)
	testing.expect(t, first_alt_ok)
	testing.expect_value(t, len(first_alt_arr.value), 1)

	prefix_term := first_alt_arr.value[0]
	prefix_term_arr, prefix_term_ok := prefix_term.value.(DoArray)
	testing.expect(t, prefix_term_ok)
	testing.expect(t, prefix_term_arr.value[0] == &lang.UnrolledProductions[.PREFIX_OPERATORS])
	testing.expect_value(t, len(prefix_term.nodes), 1)
	free_all()
}

// @(test)
// test_search_in_add_array_simple :: proc(t: ^testing.T) {
// 	tok := Token {
// 		type = .KEYWORD,
// 		kind = Keyword.INT,
// 	}

// 	leaf := GNode {
// 		value = tok,
// 	}

// 	root := GNode {
// 		value = DoArray{value = []^GNode{&leaf}},
// 	}

// 	ptr := GrammarNode_SearchInAddArray(&root, tok)

// 	testing.expect(t, ptr != nil)
// 	testing.expect(t, ptr == &leaf)

// 	free_all()
// }

// @(test)
// test_search_in_add_array_not_found :: proc(t: ^testing.T) {
// 	leaf := GNode {
// 		value = Token{type = .KEYWORD, kind = Keyword.FLOAT},
// 	}

// 	root := GNode {
// 		value = DoArray{value = []^GNode{&leaf}},
// 	}

// 	ptr := GrammarNode_SearchInAddArray(&root, Token{type = .KEYWORD, kind = Keyword.INT})

// 	testing.expect(t, ptr == nil)
// 	free_all()
// }

// @(test)
// test_search_in_add_array_recursive :: proc(t: ^testing.T) {
// 	target := GNode {
// 		value = Token{type = .KEYWORD, kind = Keyword.INT},
// 	}

// 	inner := GNode {
// 		value = DoArray{value = []^GNode{&target}},
// 	}

// 	outer := GNode {
// 		value = DoArray{value = []^GNode{&inner}},
// 	}

// 	ptr := GrammarNode_SearchInAddArray(&outer, Token{type = .KEYWORD, kind = Keyword.INT})

// 	testing.expect(t, ptr == &target)
// 	free_all()
// }

// @(test)
// test_match_token_direct :: proc(t: ^testing.T) {
// 	child := GNode {
// 		value = Token{type = .KEYWORD, kind = Keyword.INT},
// 	}

// 	root := GNode{}
// 	append(&root.nodes, &child)

// 	ptr, err := GrammarNode_MatchToken(&root, Token{type = .KEYWORD, kind = Keyword.INT})

// 	testing.expect(t, err == .OK)
// 	testing.expect(t, ptr == &child)
// 	free_all()
// }

// @(test)
// test_match_token_inside_doarray :: proc(t: ^testing.T) {
// 	tok := GNode {
// 		value = Token{type = .KEYWORD, kind = Keyword.INT},
// 	}

// 	array := GNode {
// 		value = DoArray{value = []^GNode{&tok}},
// 	}

// 	root := GNode{}
// 	append(&root.nodes, &array)

// 	ptr, err := GrammarNode_MatchToken(&root, Token{type = .KEYWORD, kind = Keyword.INT})

// 	testing.expect(t, err == .OK)
// 	testing.expect(t, ptr == &tok)
// 	free_all()
// }

// @(test)
// test_match_token_failure :: proc(t: ^testing.T) {
// 	root := GNode{}

// 	_, err := GrammarNode_MatchToken(&root, Token{type = .KEYWORD, kind = Keyword.INT})

// 	testing.expect(t, err == .COULD_NOT_MATCH)
// 	free_all()
// }

// @(test)
// test_unroll_term_token_gpt :: proc(t: ^testing.T) {
// 	tok := Token {
// 		type = .KEYWORD,
// 		kind = Keyword.INT,
// 	}

// 	node := Unroll_Term(tok)

// 	_, ok := node.value.(Token)

// 	testing.expect(t, ok)
// 	testing.expect(t, match(node.value.(Token), tok))
// 	free_all()
// }

// @(test)
// test_unroll_term_production :: proc(t: ^testing.T) {
// 	lang.UnrolledProductions = {}

// 	node := Unroll_Term(ProductionName.DECIMAL_TYPE)

// 	testing.expect(t, node.prodStart == .DECIMAL_TYPE)
// 	free_all()
// }

// @(test)
// test_unroll_expression_single :: proc(t: ^testing.T) {
// 	expr := Expression{Alternative{Token{type = .KEYWORD, kind = Keyword.INT}}}

// 	node := Unroll_Expression(expr)

// 	_, ok := node.value.(Token)

// 	testing.expect(t, ok)
// 	free_all()
// }

// @(test)
// test_unroll_expression_multiple :: proc(t: ^testing.T) {
// 	expr := Expression {
// 		Alternative{Token{type = .KEYWORD, kind = Keyword.INT}},
// 		Alternative{Token{type = .KEYWORD, kind = Keyword.FLOAT}},
// 	}

// 	node := Unroll_Expression(expr)

// 	arr, ok := node.value.(DoArray)

// 	testing.expect(t, ok)
// 	testing.expect(t, len(arr.value) == 2)
// 	free_all()
// }

// @(test)
// test_unroll_alternative_chain :: proc(t: ^testing.T) {
// 	alt := Alternative {
// 		Token{type = .KEYWORD, kind = Keyword.INT},
// 		Token{type = .IDENTIFIER},
// 		Token{type = .DELIMITER, kind = Delimiter.SEMICOLUMN},
// 	}

// 	node := Unroll_Alternative(alt)

// 	arr := node.value.(DoArray)

// 	testing.expect(t, len(arr.value) == 3)

// 	first := arr.value[0]
// 	second := arr.value[1]

// 	testing.expect(t, len(first.nodes) == 1)
// 	testing.expect(t, first.nodes[0] == second)
// 	free_all()
// }

// @(test)
// test_unroll_group_skippable :: proc(t: ^testing.T) {
// 	grp := Group {
// 		Expression{Alternative{Token{type = .KEYWORD, kind = Keyword.INT}}},
// 		Expression{Alternative{Token{type = .KEYWORD, kind = Keyword.FLOAT}}},
// 	}

// 	node := Unroll_Group(grp)

// 	arr := node.value.(DoArray)

// 	testing.expect(t, arr.skippable)
// 	testing.expect(t, len(arr.value) == 2)
// 	free_all()
// }

// @(test)
// test_unroll_option :: proc(t: ^testing.T) {
// 	opt := Option{Expression{Alternative{Token{type = .KEYWORD, kind = Keyword.INT}}}}

// 	node := Unroll_Option(opt)

// 	arr := node.value.(DoArray)

// 	testing.expect(t, arr.skippable)
// 	testing.expect(t, len(arr.value) == 1)
// 	free_all()
// }

// @(test)
// test_unroll_repetition :: proc(t: ^testing.T) {
// 	rep := Repetition {
// 		Expression{Alternative{Token{type = .KEYWORD, kind = Keyword.INT}}},
// 		Expression{Alternative{Token{type = .KEYWORD, kind = Keyword.FLOAT}}},
// 	}

// 	node := Unroll_Repetition(rep)

// 	arr := node.value.(DoArray)

// 	testing.expect(t, len(arr.value) == 2)

// 	last := arr.value[len(arr.value) - 1]

// 	testing.expect(t, last.endOfRepetition)
// 	free_all()
// }
