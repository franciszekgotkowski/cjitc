package tests

// Test suite for the grammar-tree building blocks in ggraph.odin:
//   - Token_Match          (lexer.odin)
//   - GrammarNode_MatchToken / GrammarNode_SearchInAddArray (ggraph.odin, private tested indirectly)
//   - Unroll_Production / Unroll_Expression / Unroll_Alternative / Unroll_Term
//     Unroll_Group / Unroll_Option / Unroll_Repetition
//
// Run with:  odin test .
//
// NOTES / CAVEATS (please read):
//
// 1. ggraph.odin calls `match(...)`, but the only matching proc shown to me
//    is `Token_Match`. These tests call `Token_Match` directly. If your real
//    `match` proc has different semantics, mirror these tests against it too.
//
// 2. `UnrolledProductions` is a package-level global cache mutated by
//    `Unroll_Term`. Odin's test runner executes @(test) procs in parallel,
//    so tests that unroll the *same* ProductionName could race. I've kept
//    each production-cache test on a distinct ProductionName to avoid that,
//    but if you add more such tests, keep that constraint in mind (or add
//    a way to reset the cache between tests).
//
// 3. `Unroll_Alternative` and `Unroll_Repetition` have linking behavior that
//    looks like it might be a bug (see file header of the response). The
//    tests below assert the CURRENT behavior so they'll flag it clearly if
//    you change it - they are not a statement that the behavior is correct.

import lang "../src"
import "core:testing"

// ---------------------------------------------------------------------------
// Token_Match
// ---------------------------------------------------------------------------


@(test)
test_token_match_same_type_same_kind :: proc(t: ^testing.T) {
	a := Token {
		type = .KEYWORD,
		kind = Keyword.INT,
	}
	b := Token {
		type = .KEYWORD,
		kind = Keyword.INT,
	}
	testing.expect(t, Token_Match(a, b), "same type + same kind should match")
	free_all()
}

@(test)
test_token_match_same_type_diff_kind :: proc(t: ^testing.T) {
	a := Token {
		type = .KEYWORD,
		kind = Keyword.INT,
	}
	b := Token {
		type = .KEYWORD,
		kind = Keyword.FLOAT,
	}
	testing.expect(t, !Token_Match(a, b), "same type but different kind should not match")
	free_all()
}

@(test)
test_token_match_different_type :: proc(t: ^testing.T) {
	a := Token {
		type = .KEYWORD,
		kind = Keyword.INT,
	}
	b := Token {
		type = .OPERATOR,
		kind = Operator.EQUAL,
	}
	testing.expect(t, !Token_Match(a, b), "different token types should never match")
	free_all()
}

@(test)
test_token_match_literal_requires_same_kind :: proc(t: ^testing.T) {
	// Unlike IDENTIFIER, LITERAL still distinguishes kind (DECIMAL vs
	// CHARACTER vs FLOAT vs TEXT are not interchangeable).
	a := Token {
		type = .LITERAL,
		kind = Literal.DECIMAL,
	}
	b := Token {
		type = .LITERAL,
		kind = Literal.CHARACTER,
	}
	testing.expect(t, !Token_Match(a, b), "LITERAL tokens of different kind should not match")
	free_all()
}

@(test)
test_token_match_identifier_ignores_kind :: proc(t: ^testing.T) {
	a := Token {
		type = .IDENTIFIER,
	}
	b := Token {
		type = .IDENTIFIER,
	}
	testing.expect(t, Token_Match(a, b), "IDENTIFIER tokens should match regardless of kind")
	free_all()
}

// ---------------------------------------------------------------------------
// GrammarNode_MatchToken
//
// GrammarNode_SearchInAddArray is `@(private = "file")` in ggraph.odin, so it
// can't be called directly from this file. It's exercised indirectly through
// GrammarNode_MatchToken whenever one of `node.nodes` is a DoArray.
// ---------------------------------------------------------------------------

@(test)
test_match_token_direct_hit :: proc(t: ^testing.T) {
	n1 := new(GNode)
	n1.value = Token {
		type = .KEYWORD,
		kind = Keyword.INT,
	}

	n2 := new(GNode)
	n2.value = Token {
		type = .IDENTIFIER,
	}

	root := new(GNode)
	append(&root.nodes, n1)
	append(&root.nodes, n2)

	result, err := GrammarNode_MatchToken(root, Token{type = .IDENTIFIER})
	testing.expect(t, err == .OK, "expected a successful match")
	testing.expect(t, result == n2, "expected the identifier node to be returned")
	free_all()
}

@(test)
test_match_token_no_match :: proc(t: ^testing.T) {
	n1 := new(GNode)
	n1.value = Token {
		type = .KEYWORD,
		kind = Keyword.INT,
	}

	root := new(GNode)
	append(&root.nodes, n1)

	_, err := GrammarNode_MatchToken(root, Token{type = .DELIMITER, kind = Delimiter.SEMICOLUMN})
	testing.expect(t, err == .COULD_NOT_MATCH, "expected COULD_NOT_MATCH when no child matches")
	free_all()
}

@(test)
test_match_token_finds_inside_doarray :: proc(t: ^testing.T) {
	inner_int := new(GNode)
	inner_int.value = Token {
		type = .KEYWORD,
		kind = Keyword.INT,
	}

	inner_float := new(GNode)
	inner_float.value = Token {
		type = .KEYWORD,
		kind = Keyword.FLOAT,
	}

	arr_node := new(GNode)
	arr_node.value = DoArray {
		skippable = true,
		value     = []^GNode{inner_int, inner_float},
	}

	root := new(GNode)
	append(&root.nodes, arr_node)

	result, err := GrammarNode_MatchToken(root, Token{type = .KEYWORD, kind = Keyword.FLOAT})
	testing.expect(t, err == .OK, "expected the token buried in the DoArray to be found")
	testing.expect(t, result == inner_float, "expected the matching inner node to be returned")
	free_all()
}

@(test)
test_match_token_recurses_into_nested_doarray :: proc(t: ^testing.T) {
	deepest := new(GNode)
	deepest.value = Token {
		type = .DELIMITER,
		kind = Delimiter.SEMICOLUMN,
	}

	nested_arr := new(GNode)
	nested_arr.value = DoArray {
		skippable = false,
		value     = []^GNode{deepest},
	}

	outer_arr := new(GNode)
	outer_arr.value = DoArray {
		skippable = true,
		value     = []^GNode{nested_arr},
	}

	root := new(GNode)
	append(&root.nodes, outer_arr)

	result, err := GrammarNode_MatchToken(
		root,
		Token{type = .DELIMITER, kind = Delimiter.SEMICOLUMN},
	)
	testing.expect(t, err == .OK, "expected a match through a nested DoArray")
	testing.expect(t, result == deepest, "expected the deepest matching node to be returned")
	free_all()
}

@(test)
test_match_token_no_match_inside_doarray :: proc(t: ^testing.T) {
	inner_int := new(GNode)
	inner_int.value = Token {
		type = .KEYWORD,
		kind = Keyword.INT,
	}

	arr_node := new(GNode)
	arr_node.value = DoArray {
		skippable = true,
		value     = []^GNode{inner_int},
	}

	root := new(GNode)
	append(&root.nodes, arr_node)

	_, err := GrammarNode_MatchToken(root, Token{type = .KEYWORD, kind = Keyword.FLOAT})
	testing.expect(t, err == .COULD_NOT_MATCH, "no matching token inside the DoArray should fail")
	free_all()
}

// ---------------------------------------------------------------------------
// Unroll_Term (plain Token, no ProductionName recursion)
// ---------------------------------------------------------------------------

@(test)
test_unroll_term_token :: proc(t: ^testing.T) {
	term: Term = Token {
		type = .KEYWORD,
		kind = Keyword.INT,
	}
	node := Unroll_Term(term)

	tok, ok := node.value.(Token)
	testing.expect(t, ok, "expected node.value to hold a Token")
	testing.expect(t, tok.type == .KEYWORD, "expected KEYWORD token type")
	testing.expect(t, tok.kind == Keyword.INT, "expected INT keyword kind")
	free_all()
}

// ---------------------------------------------------------------------------
// Unroll_Expression
// ---------------------------------------------------------------------------

@(test)
test_unroll_expression_single_alternative_shortcuts :: proc(t: ^testing.T) {
	// len(expr) == 1 should skip wrapping in a DoArray entirely.
	expr := Expression{Alternative{Token{type = .IDENTIFIER}}}
	node := Unroll_Expression(expr)

	_, ok := node.value.(Token)
	testing.expect(t, ok, "single-alternative expression should unwrap directly to a Token")
	free_all()
}

@(test)
test_unroll_expression_multiple_alternatives_wraps_in_doarray :: proc(t: ^testing.T) {
	expr := Expression {
		Alternative{Token{type = .KEYWORD, kind = Keyword.INT}},
		Alternative{Token{type = .KEYWORD, kind = Keyword.FLOAT}},
	}
	node := Unroll_Expression(expr)

	arr, ok := node.value.(DoArray)
	testing.expect(t, ok, "multi-alternative expression should produce a DoArray")
	testing.expect(t, !arr.skippable, "Unroll_Expression should mark the DoArray as not skippable")
	testing.expect_value(t, len(arr.value), 2)
	free_all()
}

// ---------------------------------------------------------------------------
// Unroll_Alternative
//
// CURRENT (possibly unintended) linking behavior, see header notes.
// ---------------------------------------------------------------------------

@(test)
test_unroll_alternative_single_term_shortcuts :: proc(t: ^testing.T) {
	alt := Alternative{Token{type = .IDENTIFIER}}
	node := Unroll_Alternative(alt)

	_, ok := node.value.(Token)
	testing.expect(t, ok, "single-term alternative should unwrap directly to a Token")
	free_all()
}

@(test)
test_unroll_alternative_two_terms_linking :: proc(t: ^testing.T) {
	alt := Alternative{Token{type = .KEYWORD, kind = Keyword.INT}, Token{type = .IDENTIFIER}}
	node := Unroll_Alternative(alt)

	arr, ok := node.value.(DoArray)
	testing.expect(t, ok, "multi-term alternative should produce a DoArray")
	// DoArray.value is always a single entry point; the rest of the
	// sequence is reachable through .nodes, which is what
	// ParseGnodeChildren walks to consume subsequent terms.
	testing.expect_value(t, len(arr.value), 1)

	first := arr.value[0]

	testing.expect_value(t, len(first.nodes), 1)
	if len(first.nodes) == 1 {
		second := first.nodes[0]
		_, is_identifier_token := second.value.(Token)
		testing.expect(t, is_identifier_token, "term[0] should link to term[1]")
	}
	free_all()
}

@(test)
test_unroll_alternative_three_terms_linking :: proc(t: ^testing.T) {
	alt := Alternative {
		Token{type = .KEYWORD, kind = Keyword.INT},
		Token{type = .IDENTIFIER},
		Token{type = .DELIMITER, kind = Delimiter.SEMICOLUMN},
	}
	node := Unroll_Alternative(alt)

	arr, ok := node.value.(DoArray)
	testing.expect(t, ok, "multi-term alternative should produce a DoArray")
	testing.expect_value(t, len(arr.value), 1)

	// The chain is: entry -> term[1] -> term[2], each reachable via .nodes.
	first := arr.value[0]
	testing.expect_value(t, len(first.nodes), 1)
	if len(first.nodes) != 1 do return

	second := first.nodes[0]
	testing.expect_value(t, len(second.nodes), 1)
	if len(second.nodes) != 1 do return

	third := second.nodes[0]
	_, third_is_semicolon := third.value.(Token)
	testing.expect(t, third_is_semicolon, "term[2] should be reachable via term[1].nodes[0]")
	testing.expect_value(t, len(third.nodes), 0)
	free_all()
}

// ---------------------------------------------------------------------------
// Unroll_Group
// ---------------------------------------------------------------------------

@(test)
test_unroll_group_single_expression_shortcuts :: proc(t: ^testing.T) {
	group := Group{Expression{Alternative{Token{type = .IDENTIFIER}}}}
	node := Unroll_Group(group)

	_, ok := node.value.(Token)
	testing.expect(t, ok, "single-expression group should unwrap directly, no DoArray wrapper")
	free_all()
}

@(test)
test_unroll_group_multiple_expressions_are_skippable :: proc(t: ^testing.T) {
	group := Group {
		Expression{Alternative{Token{type = .KEYWORD, kind = Keyword.INT}}},
		Expression{Alternative{Token{type = .KEYWORD, kind = Keyword.FLOAT}}},
	}
	node := Unroll_Group(group)

	arr, ok := node.value.(DoArray)
	testing.expect(t, ok, "multi-expression group should produce a DoArray")
	testing.expect(t, arr.skippable, "Unroll_Group should mark the DoArray as skippable")
	testing.expect_value(t, len(arr.value), 2)
	free_all()
}

// ---------------------------------------------------------------------------
// Unroll_Option
//
// Unlike Unroll_Group, Unroll_Option has no length==1 shortcut, so it always
// wraps its (always single) expression in a skippable DoArray.
// ---------------------------------------------------------------------------

@(test)
test_unroll_option_always_wraps_in_doarray :: proc(t: ^testing.T) {
	opt := Option{Expression{Alternative{Token{type = .IDENTIFIER}}}}
	node := Unroll_Option(opt)

	arr, ok := node.value.(DoArray)
	testing.expect(t, ok, "Unroll_Option should always produce a DoArray, even for length 1")
	testing.expect(t, arr.skippable, "Unroll_Option should mark the DoArray as skippable")
	testing.expect_value(t, len(arr.value), 1)
	free_all()
}

// ---------------------------------------------------------------------------
// Unroll_Repetition
//
// CURRENT behavior: every element links to (i+1) % len, so the whole thing
// forms a closed cycle (including last -> first), while only the last
// element is flagged endOfRepetition. See header notes.
// ---------------------------------------------------------------------------

@(test)
test_unroll_repetition_single_element_self_loops :: proc(t: ^testing.T) {
	rep := Repetition{Expression{Alternative{Token{type = .IDENTIFIER}}}}
	node := Unroll_Repetition(rep)

	arr, ok := node.value.(DoArray)
	testing.expect(t, ok, "repetition should produce a DoArray")
	testing.expect_value(t, len(arr.value), 1)

	only := arr.value[0]
	testing.expect(t, only.endOfRepetition, "the single element should be marked endOfRepetition")
	testing.expect_value(t, len(only.nodes), 1)
	if len(only.nodes) == 1 {
		testing.expect(t, only.nodes[0] == only, "single-element repetition currently self-loops")
	}
	free_all()
}

@(test)
test_unroll_repetition_two_elements_form_a_cycle :: proc(t: ^testing.T) {
	rep := Repetition {
		Expression{Alternative{Token{type = .KEYWORD, kind = Keyword.INT}}},
		Expression{Alternative{Token{type = .IDENTIFIER}}},
	}
	node := Unroll_Repetition(rep)

	arr, ok := node.value.(DoArray)
	testing.expect(t, ok, "repetition should produce a DoArray")
	// Single entry point, like Unroll_Alternative; the cycle lives in .nodes.
	testing.expect_value(t, len(arr.value), 1)

	first := arr.value[0]
	testing.expect(t, !first.endOfRepetition, "only the last element should be endOfRepetition")
	testing.expect_value(t, len(first.nodes), 1)
	if len(first.nodes) != 1 do return

	second := first.nodes[0]
	testing.expect(t, second.endOfRepetition, "last element should be marked endOfRepetition")
	testing.expect_value(t, len(second.nodes), 1)
	if len(second.nodes) == 1 {
		testing.expect(t, second.nodes[0] == first, "term[1] wraps back to term[0], closing the repetition cycle")
	}
	free_all()
}

// ---------------------------------------------------------------------------
// Unroll_Production (uses distinct ProductionNames per test to avoid
// clobbering the shared UnrolledProductions cache across parallel tests)
// ---------------------------------------------------------------------------

@(test)
test_unroll_production_simple_token :: proc(t: ^testing.T) {
	node := Unroll_Production(lang.Productions[.DECIMAL_LITERAL], .DECIMAL_LITERAL)

	_, ok := node.value.(Token)
	testing.expect(t, ok, "DECIMAL_LITERAL should unroll straight down to a Token")

	name, has_name := node.prodStart.?
	testing.expect(t, has_name, "prodStart should be set")
	testing.expect(t, name == .DECIMAL_LITERAL, "prodStart should be DECIMAL_LITERAL")
	free_all()
}

@(test)
test_unroll_production_with_alternatives_sets_prod_start :: proc(t: ^testing.T) {
	node := Unroll_Production(lang.Productions[.LITERALS], .LITERALS)

	arr, ok := node.value.(DoArray)
	testing.expect(t, ok, "LITERALS has multiple alternatives, so it should produce a DoArray")
	testing.expect_value(t, len(arr.value), len(lang.Productions[.LITERALS]))

	name, has_name := node.prodStart.?
	testing.expect(t, has_name, "prodStart should be set")
	testing.expect(t, name == .LITERALS, "prodStart should be LITERALS")
	free_all()
}

@(test)
test_unroll_term_production_name_points_at_slot :: proc(t: ^testing.T) {
	// Unroll_Term no longer builds/caches on demand: it must return a
	// DoArray wrapper whose single element is a pointer into the
	// UnrolledProductions array slot for that name. It's PrepareGrammarGraph
	// (not Unroll_Term) that's responsible for actually filling that slot in.
	lang.UnrolledProductions = {}

	node := Unroll_Term(ProductionName.FLOAT_TYPE)

	arr, ok := node.value.(DoArray)
	testing.expect(t, ok, "ProductionName term should unroll to a DoArray wrapper")
	testing.expect_value(t, len(arr.value), 1)
	testing.expect(t, arr.value[0] == &lang.UnrolledProductions[.FLOAT_TYPE], "wrapper should point at the UnrolledProductions slot")
	free_all()
}
