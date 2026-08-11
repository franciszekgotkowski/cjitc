package tests

// Test suite for ParseTokens (parse_tree.odin): construction of ParseNode
// ("parse node") trees from a token stream + the already-built grammar
// graph.
//
// These deliberately reuse the project's real grammar (Productions /
// ProductionName in grammar_constants.odin) rather than any synthetic
// grammar, and drive it with hand-built Token slices (no lexer needed,
// since match()/Token_Match only look at type+kind).
//
// A prior bug in ParseTokens made two independent ParseNode.next dynamic
// arrays silently alias the same backing storage, so the constructed
// "tree" ended up cyclic/absurdly oversized instead of shaped like the
// input. Because of that, the helpers below never trust the tree size and
// walk with an explicit stack + hard node budget rather than plain
// recursion, so a regression fails a testing.expect() instead of
// stack-overflowing the whole test binary.

import lang "../src"
import "core:testing"

PNode :: lang.PNode
ParseTokens :: lang.ParseTokens
ParseError :: lang.ParseError
PrepareGrammarGraph :: lang.PrepareGrammarGraph

@(private = "file")
NODE_BUDGET :: 10_000

// Every Token-valued leaf in the tree, in left-to-right document order
// (i.e. the order ParseTokens actually consumed them from the input).
@(private = "file")
collect_leaf_tokens :: proc(root: ^PNode) -> (leaves: [dynamic]Token, node_count: int, exceeded: bool) {
	stack: [dynamic]^PNode
	append(&stack, root)

	for len(stack) > 0 {
		n := pop(&stack)
		node_count += 1
		if node_count > NODE_BUDGET {
			exceeded = true
			return
		}

		if tok, ok := n.value.(Token); ok {
			append(&leaves, tok)
		}

		// push back-to-front so they pop (and get visited) in original order
		for i := len(n.next) - 1; i >= 0; i -= 1 {
			append(&stack, &n.next[i])
		}
	}
	return
}

@(private = "file")
count_nodes :: proc(root: ^PNode) -> (total: int, exceeded: bool) {
	stack: [dynamic]^PNode
	append(&stack, root)
	for len(stack) > 0 {
		n := pop(&stack)
		total += 1
		if total > NODE_BUDGET {
			exceeded = true
			return
		}
		for _, i in n.next {
			append(&stack, &n.next[i])
		}
	}
	return
}

@(private = "file")
count_labeled :: proc(root: ^PNode, name: ProductionName) -> (count: int, exceeded: bool) {
	stack: [dynamic]^PNode
	append(&stack, root)
	visited := 0
	for len(stack) > 0 {
		n := pop(&stack)
		visited += 1
		if visited > NODE_BUDGET {
			exceeded = true
			return
		}
		if pn, ok := n.value.(ProductionName); ok && pn == name {
			count += 1
		}
		for _, i in n.next {
			append(&stack, &n.next[i])
		}
	}
	return
}

@(private = "file")
tokens_equal :: proc(a, b: []Token) -> bool {
	if len(a) != len(b) do return false
	for v, i in a {
		if v.type != b[i].type || v.kind != b[i].kind do return false
	}
	return true
}

// Runs ParseTokens against a real, named top-level production. Since the
// entry node always has prodStart set and procStart starts false, the
// outermost return is always the plain PNode case of the result union
// (see the `if name, ok := gnode.prodStart.?; ok && !procStart` branch in
// parse_tree.odin), so callers can rely on that here instead of every test
// re-deriving it.
@(private = "file")
parse_production :: proc(name: ProductionName, tokens: []Token) -> (root: PNode, remaining: []Token, err: ParseError) {
	PrepareGrammarGraph()
	result: union {
		PNode,
		[2]PNode,
	}
	result, remaining, err = ParseTokens(PNode{}, &lang.UnrolledProductions[name], tokens)
	if err != .OK do return
	root = result.(PNode)
	return
}

@(test)
test_parse_decimal_literal_leaf :: proc(t: ^testing.T) {
	input := []Token{{type = .LITERAL, kind = Literal.DECIMAL}}

	root, remaining, err := parse_production(.DECIMAL_LITERAL, input)

	testing.expect(t, err == .OK)
	testing.expect_value(t, len(remaining), 0)

	count, exceeded_budget := count_labeled(&root, .DECIMAL_LITERAL)
	testing.expect(t, !exceeded_budget, "count_labeled should not hit the node budget")
	testing.expect_value(t, count, 1)

	leaves, node_count, exceeded := collect_leaf_tokens(&root)
	testing.expect(t, !exceeded)
	testing.expect(t, node_count < 20, "a single-token production shouldn't need many nodes")
	testing.expect(t, tokens_equal(leaves[:], input))
	free_all()
}

@(test)
test_parse_float_literal_sequence :: proc(t: ^testing.T) {
	// FLOAT_LITERAL = DECIMAL "." DECIMAL, a 3-term Alternative chained
	// through .nodes rather than stored flat in DoArray.value.
	input := []Token {
		{type = .LITERAL, kind = Literal.DECIMAL},
		{type = .OPERATOR, kind = Operator.DOT},
		{type = .LITERAL, kind = Literal.DECIMAL},
	}

	root, remaining, err := parse_production(.FLOAT_LITERAL, input)

	testing.expect(t, err == .OK)
	testing.expect_value(t, len(remaining), 0)

	leaves, _, exceeded := collect_leaf_tokens(&root)
	testing.expect(t, !exceeded)
	testing.expect(t, tokens_equal(leaves[:], input), "leaves should reconstruct the input in order")
	free_all()
}

@(test)
test_parse_literals_backtracks_to_decimal :: proc(t: ^testing.T) {
	// LITERALS tries FLOAT_LITERAL first, which needs 3 tokens; a single
	// DECIMAL token must fail that and fall back to DECIMAL_LITERAL.
	input := []Token{{type = .LITERAL, kind = Literal.DECIMAL}}

	root, remaining, err := parse_production(.LITERALS, input)

	testing.expect(t, err == .OK)
	testing.expect_value(t, len(remaining), 0)

	c1, _ := count_labeled(&root, .LITERALS)
	c2, _ := count_labeled(&root, .DECIMAL_LITERAL)
	c3, _ := count_labeled(&root, .FLOAT_LITERAL)
	testing.expect_value(t, c1, 1)
	testing.expect_value(t, c2, 1)
	testing.expect_value(t, c3, 0)
	free_all()
}

@(test)
test_parse_literals_picks_char :: proc(t: ^testing.T) {
	input := []Token{{type = .LITERAL, kind = Literal.CHARACTER}}

	root, remaining, err := parse_production(.LITERALS, input)

	testing.expect(t, err == .OK)
	testing.expect_value(t, len(remaining), 0)

	c, _ := count_labeled(&root, .CHAR_LITERAL)
	testing.expect_value(t, c, 1)
	free_all()
}

@(test)
test_parse_declaration_sequence :: proc(t: ^testing.T) {
	// DECLARATION = TYPES IDENTIFIER ";"
	input := []Token {
		{type = .KEYWORD, kind = Keyword.INT},
		{type = .IDENTIFIER},
		{type = .DELIMITER, kind = Delimiter.SEMICOLUMN},
	}

	root, remaining, err := parse_production(.DECLARATION, input)

	testing.expect(t, err == .OK)
	testing.expect_value(t, len(remaining), 0)

	leaves, _, exceeded := collect_leaf_tokens(&root)
	testing.expect(t, !exceeded)
	testing.expect(t, tokens_equal(leaves[:], input))

	c_decl, _ := count_labeled(&root, .DECLARATION)
	c_types, _ := count_labeled(&root, .TYPES)
	c_dtype, _ := count_labeled(&root, .DECIMAL_TYPE)
	testing.expect_value(t, c_decl, 1)
	testing.expect_value(t, c_types, 1)
	testing.expect_value(t, c_dtype, 1)
	free_all()
}

@(test)
test_parse_declaration_with_assignment :: proc(t: ^testing.T) {
	// RHS is ProductionName.EXPRESSION (not .LITERALS directly), so a bare
	// literal must still work by EXPRESSION resolving to LITERALS first.
	input := []Token {
		{type = .KEYWORD, kind = Keyword.FLOAT},
		{type = .IDENTIFIER},
		{type = .OPERATOR, kind = Operator.EQUAL},
		{type = .LITERAL, kind = Literal.DECIMAL},
		{type = .DELIMITER, kind = Delimiter.SEMICOLUMN},
	}

	root, remaining, err := parse_production(.DECLARATION_WITH_ASSIGNMENT, input)

	testing.expect(t, err == .OK)
	testing.expect_value(t, len(remaining), 0)

	leaves, _, exceeded := collect_leaf_tokens(&root)
	testing.expect(t, !exceeded)
	testing.expect(t, tokens_equal(leaves[:], input))

	c_expr, _ := count_labeled(&root, .EXPRESSION)
	testing.expect_value(t, c_expr, 1)
	free_all()
}

@(test)
test_parse_declaration_with_assignment_to_variable :: proc(t: ^testing.T) {
	// Regression coverage for the RHS having widened from .LITERALS to
	// .EXPRESSION: assigning from another variable (not just a literal)
	// must now be accepted too.
	//
	// Note: EXPRESSION resolves a bare identifier through OPERATOR_EXPRESSION
	// (tried before VARIABLE_NAME), since UNARY_EXPRESSIONS' third
	// alternative accepts a lone identifier with no operator - so this
	// checks the leaves match rather than which specific label EXPRESSION
	// picked.
	input := []Token {
		{type = .KEYWORD, kind = Keyword.INT},
		{type = .IDENTIFIER}, // x
		{type = .OPERATOR, kind = Operator.EQUAL},
		{type = .IDENTIFIER}, // y
		{type = .DELIMITER, kind = Delimiter.SEMICOLUMN},
	}

	root, remaining, err := parse_production(.DECLARATION_WITH_ASSIGNMENT, input)

	testing.expect(t, err == .OK)
	testing.expect_value(t, len(remaining), 0)

	leaves, _, exceeded := collect_leaf_tokens(&root)
	testing.expect(t, !exceeded)
	testing.expect(t, tokens_equal(leaves[:], input))
	free_all()
}

@(test)
test_parse_decls_backtracks_to_plain_declaration :: proc(t: ^testing.T) {
	// DECLS tries DECLARATION_WITH_ASSIGNMENT first (needs 5 tokens incl.
	// "=" + a literal); a plain "int x;" (3 tokens) must fail that and
	// fall back to the DECLARATION alternative.
	input := []Token {
		{type = .KEYWORD, kind = Keyword.INT},
		{type = .IDENTIFIER},
		{type = .DELIMITER, kind = Delimiter.SEMICOLUMN},
	}

	root, remaining, err := parse_production(.DECLS, input)

	testing.expect(t, err == .OK)
	testing.expect_value(t, len(remaining), 0)

	c_decls, _ := count_labeled(&root, .DECLS)
	c_decl, _ := count_labeled(&root, .DECLARATION)
	c_decl_assign, _ := count_labeled(&root, .DECLARATION_WITH_ASSIGNMENT)
	testing.expect_value(t, c_decls, 1)
	testing.expect_value(t, c_decl, 1)
	testing.expect_value(t, c_decl_assign, 0)
	free_all()
}

// @(test)
// test_parse_function_call_no_args :: proc(t: ^testing.T) {
// 	// The Option wrapping the argument list must be skippable without
// 	// leaving any phantom leaves behind.
// 	input := []Token {
// 		{type = .IDENTIFIER},
// 		{type = .DELIMITER, kind = Delimiter.PAREN_OPEN},
// 		{type = .DELIMITER, kind = Delimiter.PAREN_CLOSE},
// 		{type = .DELIMITER, kind = Delimiter.SEMICOLUMN},
// 	}

// 	root, remaining, err := parse_production(.FUNCTION_CALL, input)

// 	testing.expect(t, err == .OK)
// 	testing.expect_value(t, len(remaining), 0)

// 	leaves, _, exceeded := collect_leaf_tokens(&root)
// 	testing.expect(t, !exceeded)
// 	testing.expect(t, tokens_equal(leaves[:], input), "no-arg call should consume exactly its 4 tokens, nothing more")
// 	free_all()
// }

// @(test)
// test_parse_function_call_multiple_args :: proc(t: ^testing.T) {
// 	// Regression test: this Repetition (", " EXPRESSION)* is exactly the
// 	// construct whose self-referencing GNode used to blow up into a
// 	// multi-million-node ParseNode chain due to aliased .next backing
// 	// arrays. A handful of comma-separated args should stay small and
// 	// reconstruct exactly.
// 	input := []Token {
// 		{type = .IDENTIFIER},
// 		{type = .DELIMITER, kind = Delimiter.PAREN_OPEN},
// 		{type = .LITERAL, kind = Literal.DECIMAL},
// 		{type = .DELIMITER, kind = Delimiter.COMMA},
// 		{type = .LITERAL, kind = Literal.DECIMAL},
// 		{type = .DELIMITER, kind = Delimiter.COMMA},
// 		{type = .LITERAL, kind = Literal.CHARACTER},
// 		{type = .DELIMITER, kind = Delimiter.COMMA},
// 		{type = .LITERAL, kind = Literal.DECIMAL},
// 		{type = .DELIMITER, kind = Delimiter.PAREN_CLOSE},
// 		{type = .DELIMITER, kind = Delimiter.SEMICOLUMN},
// 	}

// 	root, remaining, err := parse_production(.FUNCTION_CALL, input)

// 	testing.expect(t, err == .OK)
// 	testing.expect_value(t, len(remaining), 0)

// 	total, exceeded := count_nodes(&root)
// 	testing.expect(t, !exceeded, "node count blew past the budget - looks like the aliasing bug is back")
// 	testing.expect(t, total < 20 * len(input), "node count should scale roughly with input size, not explode")

// 	leaves, _, leaves_exceeded := collect_leaf_tokens(&root)
// 	testing.expect(t, !leaves_exceeded)
// 	testing.expect(t, tokens_equal(leaves[:], input), "leaves should reconstruct the exact input, with no duplication")

// 	c_expr, _ := count_labeled(&root, .EXPRESSION)
// 	testing.expect_value(t, c_expr, 4)
// 	free_all()
// }

@(test)
test_parse_code_entry_multiple_statements :: proc(t: ^testing.T) {
	// CODE_ENTRY = { STATEMENT } - the other historic blow-up site (its
	// repetition body node points back at itself). Two statements back to
	// back should parse to a small tree that consumes every token exactly
	// once, not grow without bound.
	declaration := []Token {
		{type = .KEYWORD, kind = Keyword.INT},
		{type = .IDENTIFIER},
		{type = .DELIMITER, kind = Delimiter.SEMICOLUMN},
	}
	call := []Token {
		{type = .IDENTIFIER},
		{type = .DELIMITER, kind = Delimiter.PAREN_OPEN},
		{type = .DELIMITER, kind = Delimiter.PAREN_CLOSE},
		{type = .DELIMITER, kind = Delimiter.SEMICOLUMN},
	}
	input: [dynamic]Token
	append(&input, ..declaration)
	append(&input, ..call)
	append(&input, ..declaration)

	root, remaining, err := parse_production(.CODE_ENTRY, input[:])

	testing.expect(t, err == .OK)
	testing.expect_value(t, len(remaining), 0)

	total, exceeded := count_nodes(&root)
	testing.expect(t, !exceeded, "node count blew past the budget - looks like the aliasing bug is back")
	testing.expect(t, total < 30 * len(input), "node count should scale roughly with input size, not explode")

	leaves, _, leaves_exceeded := collect_leaf_tokens(&root)
	testing.expect(t, !leaves_exceeded)
	testing.expect(t, tokens_equal(leaves[:], input[:]), "leaves should reconstruct all 3 statements in order")

	c_stmt, _ := count_labeled(&root, .STATEMENT)
	testing.expect_value(t, c_stmt, 3)

	// Regression check for a specific shape bug: the repetition merge used
	// to only nest the *first* STATEMENT under the CODE_ENTRY node and
	// leak the rest out as CODE_ENTRY's own siblings one level up (i.e.
	// root.next was [CODE_ENTRY{STATEMENT_1}, STATEMENT_2, STATEMENT_3]
	// instead of [CODE_ENTRY{STATEMENT_1, STATEMENT_2, STATEMENT_3}]).
	testing.expect_value(t, len(root.next), 1)
	if len(root.next) == 1 {
		code_entry := root.next[0]
		pn, is_pn := code_entry.value.(ProductionName)
		testing.expect(t, is_pn && pn == .CODE_ENTRY, "root's only child should be the CODE_ENTRY node")
		testing.expect_value(t, len(code_entry.next), 3)
		for stmt in code_entry.next {
			stmt_pn, stmt_is_pn := stmt.value.(ProductionName)
			testing.expect(t, stmt_is_pn && stmt_pn == .STATEMENT, "every statement should be a direct child of CODE_ENTRY, not a sibling of it")
		}
	}
	free_all()
}

@(test)
test_parse_mismatched_token_fails :: proc(t: ^testing.T) {
	input := []Token{{type = .IDENTIFIER}}

	_, _, err := parse_production(.DECIMAL_LITERAL, input)

	testing.expect(t, err != .OK)
	free_all()
}

@(test)
test_parse_empty_tokens_fails :: proc(t: ^testing.T) {
	PrepareGrammarGraph()
	_, remaining, err := ParseTokens(PNode{}, &lang.UnrolledProductions[ProductionName.DECIMAL_LITERAL], []Token{})

	testing.expect(t, err == .INCORRECT_INPUT)
	testing.expect(t, remaining == nil)
	free_all()
}

// ---------------------------------------------------------------------------
// Grammar added after the above tests were written: MEMBER_ACCESS_EXPRESSION
// / MEMBER_ACCESS_PTR_EXPRESSION, FUNCTION_DECLARATION, PREFIX_OPERATORS /
// POSTFIX_OPERATORS, and the reworked UNARY_EXPRESSIONS (which for the
// first time makes COMP_EXPRESSIONS/ADD_EXPRESSIONS/MUL_EXPRESSIONS
// actually reachable - UNARY_EXPRESSIONS used to be a Token{} stub that
// could never match anything).
// ---------------------------------------------------------------------------

@(test)
test_parse_member_access_expression :: proc(t: ^testing.T) {
	input := []Token {
		{type = .IDENTIFIER},
		{type = .OPERATOR, kind = Operator.DOT},
		{type = .IDENTIFIER},
	}

	root, remaining, err := parse_production(.MEMBER_ACCESS_EXPRESSION, input)

	testing.expect(t, err == .OK)
	testing.expect_value(t, len(remaining), 0)

	leaves, _, exceeded := collect_leaf_tokens(&root)
	testing.expect(t, !exceeded)
	testing.expect(t, tokens_equal(leaves[:], input))
	free_all()
}

@(test)
test_parse_member_access_ptr_expression :: proc(t: ^testing.T) {
	input := []Token {
		{type = .IDENTIFIER},
		{type = .OPERATOR, kind = Operator.RIGHT_ARROW},
		{type = .IDENTIFIER},
	}

	root, remaining, err := parse_production(.MEMBER_ACCESS_PTR_EXPRESSION, input)

	testing.expect(t, err == .OK)
	testing.expect_value(t, len(remaining), 0)

	leaves, _, exceeded := collect_leaf_tokens(&root)
	testing.expect(t, !exceeded)
	testing.expect(t, tokens_equal(leaves[:], input))
	free_all()
}

@(test)
test_parse_unary_expression_bare_identifier :: proc(t: ^testing.T) {
	input := []Token{{type = .IDENTIFIER}}

	_, remaining, err := parse_production(.UNARY_EXPRESSIONS, input)

	testing.expect(t, err == .OK)
	testing.expect_value(t, len(remaining), 0)
	free_all()
}

@(test)
test_parse_unary_expression_prefix_operator :: proc(t: ^testing.T) {
	// ++x
	input := []Token{{type = .OPERATOR, kind = Operator.PLUS_PLUS}, {type = .IDENTIFIER}}

	root, remaining, err := parse_production(.UNARY_EXPRESSIONS, input)

	testing.expect(t, err == .OK)
	testing.expect_value(t, len(remaining), 0)

	c, _ := count_labeled(&root, .PREFIX_OPERATORS)
	testing.expect_value(t, c, 1)
	free_all()
}

@(test)
test_parse_unary_expression_postfix_operator :: proc(t: ^testing.T) {
	// x++
	input := []Token{{type = .IDENTIFIER}, {type = .OPERATOR, kind = Operator.PLUS_PLUS}}

	root, remaining, err := parse_production(.UNARY_EXPRESSIONS, input)

	testing.expect(t, err == .OK)
	testing.expect_value(t, len(remaining), 0)

	c, _ := count_labeled(&root, .POSTFIX_OPERATORS)
	testing.expect_value(t, c, 1)
	free_all()
}

@(test)
test_parse_add_expressions_chain :: proc(t: ^testing.T) {
	// Regression test: MUL_EXPRESSIONS' and ADD_EXPRESSIONS' trailing
	// `{ OPERATOR OPERAND }` repetition used to be misdiagnosed as a
	// *mandatory* continuation whenever the operand it matched left no
	// tokens behind, which made "x + y" only ever consume "x". This is
	// only reachable now that UNARY_EXPRESSIONS can actually match a bare
	// identifier at the bottom of the chain.
	input := []Token {
		{type = .IDENTIFIER}, // x
		{type = .OPERATOR, kind = Operator.PLUS},
		{type = .IDENTIFIER}, // y
	}

	root, remaining, err := parse_production(.ADD_EXPRESSIONS, input)

	testing.expect(t, err == .OK)
	testing.expect_value(t, len(remaining), 0)

	leaves, _, exceeded := collect_leaf_tokens(&root)
	testing.expect(t, !exceeded)
	testing.expect(t, tokens_equal(leaves[:], input))

	c_add_op, _ := count_labeled(&root, .ADD_OPERATORS)
	c_mul, _ := count_labeled(&root, .MUL_EXPRESSIONS)
	testing.expect_value(t, c_add_op, 1)
	testing.expect_value(t, c_mul, 2)
	free_all()
}

@(test)
test_parse_operator_expression_full_chain_with_prefix :: proc(t: ^testing.T) {
	// ++x + y, all the way through
	// OPERATOR_EXPRESSION -> COMP_EXPRESSIONS -> ADD_EXPRESSIONS ->
	// MUL_EXPRESSIONS -> UNARY_EXPRESSIONS.
	input := []Token {
		{type = .OPERATOR, kind = Operator.PLUS_PLUS},
		{type = .IDENTIFIER}, // x
		{type = .OPERATOR, kind = Operator.PLUS},
		{type = .IDENTIFIER}, // y
	}

	root, remaining, err := parse_production(.OPERATOR_EXPRESSION, input)

	testing.expect(t, err == .OK)
	testing.expect_value(t, len(remaining), 0)

	leaves, _, exceeded := collect_leaf_tokens(&root)
	testing.expect(t, !exceeded)
	testing.expect(t, tokens_equal(leaves[:], input))

	c_prefix, _ := count_labeled(&root, .PREFIX_OPERATORS)
	c_add_op, _ := count_labeled(&root, .ADD_OPERATORS)
	testing.expect_value(t, c_prefix, 1)
	testing.expect_value(t, c_add_op, 1)
	free_all()
}

@(test)
test_parse_function_declaration_no_params :: proc(t: ^testing.T) {
	// Grammar as written: the body is exactly one mandatory STATEMENT (not
	// a repetition), so a function body always has exactly one statement.
	input := []Token {
		{type = .KEYWORD, kind = Keyword.INT}, // return type
		{type = .IDENTIFIER}, // function name
		{type = .DELIMITER, kind = Delimiter.PAREN_OPEN},
		{type = .DELIMITER, kind = Delimiter.PAREN_CLOSE},
		{type = .DELIMITER, kind = Delimiter.BRACE_OPEN},
		{type = .KEYWORD, kind = Keyword.INT}, // body: "int x;"
		{type = .IDENTIFIER},
		{type = .DELIMITER, kind = Delimiter.SEMICOLUMN},
		{type = .DELIMITER, kind = Delimiter.BRACE_CLOSE},
	}

	root, remaining, err := parse_production(.FUNCTION_DECLARATION, input)

	testing.expect(t, err == .OK)
	testing.expect_value(t, len(remaining), 0)

	leaves, _, exceeded := collect_leaf_tokens(&root)
	testing.expect(t, !exceeded)
	testing.expect(t, tokens_equal(leaves[:], input))

	c_stmt, _ := count_labeled(&root, .STATEMENT)
	testing.expect_value(t, c_stmt, 1)
	free_all()
}

@(test)
test_parse_function_declaration_one_param :: proc(t: ^testing.T) {
	input := []Token {
		{type = .KEYWORD, kind = Keyword.INT}, // return type
		{type = .IDENTIFIER}, // function name
		{type = .DELIMITER, kind = Delimiter.PAREN_OPEN},
		{type = .KEYWORD, kind = Keyword.INT}, // param type
		{type = .IDENTIFIER}, // param name
		{type = .DELIMITER, kind = Delimiter.PAREN_CLOSE},
		{type = .DELIMITER, kind = Delimiter.BRACE_OPEN},
		{type = .KEYWORD, kind = Keyword.INT}, // body: "int x;"
		{type = .IDENTIFIER},
		{type = .DELIMITER, kind = Delimiter.SEMICOLUMN},
		{type = .DELIMITER, kind = Delimiter.BRACE_CLOSE},
	}

	root, remaining, err := parse_production(.FUNCTION_DECLARATION, input)

	testing.expect(t, err == .OK)
	testing.expect_value(t, len(remaining), 0)

	leaves, _, exceeded := collect_leaf_tokens(&root)
	testing.expect(t, !exceeded)
	testing.expect(t, tokens_equal(leaves[:], input))
	free_all()
}

@(test)
test_parse_function_declaration_multiple_params :: proc(t: ^testing.T) {
	// Grammar as written: every parameter (including ones after the
	// first) carries its own type - "," TYPES IDENTIFIER repeated.
	input := []Token {
		{type = .KEYWORD, kind = Keyword.INT},
		{type = .IDENTIFIER},
		{type = .DELIMITER, kind = Delimiter.PAREN_OPEN},
		{type = .KEYWORD, kind = Keyword.INT},
		{type = .IDENTIFIER}, // param 1
		{type = .DELIMITER, kind = Delimiter.COMMA},
		{type = .KEYWORD, kind = Keyword.FLOAT},
		{type = .IDENTIFIER}, // param 2
		{type = .DELIMITER, kind = Delimiter.COMMA},
		{type = .KEYWORD, kind = Keyword.CHAR},
		{type = .IDENTIFIER}, // param 3
		{type = .DELIMITER, kind = Delimiter.PAREN_CLOSE},
		{type = .DELIMITER, kind = Delimiter.BRACE_OPEN},
		{type = .KEYWORD, kind = Keyword.INT}, // body: "int x;"
		{type = .IDENTIFIER},
		{type = .DELIMITER, kind = Delimiter.SEMICOLUMN},
		{type = .DELIMITER, kind = Delimiter.BRACE_CLOSE},
	}

	root, remaining, err := parse_production(.FUNCTION_DECLARATION, input)

	testing.expect(t, err == .OK)
	testing.expect_value(t, len(remaining), 0)

	leaves, _, exceeded := collect_leaf_tokens(&root)
	testing.expect(t, !exceeded)
	testing.expect(t, tokens_equal(leaves[:], input))

	c_types, _ := count_labeled(&root, .TYPES)
	testing.expect_value(t, c_types, 5) // return type + 3 param types + body statement's type
	free_all()
}

@(test)
test_parse_decls_picks_function_declaration :: proc(t: ^testing.T) {
	// DECLS tries DECLARATION_WITH_ASSIGNMENT then DECLARATION first, both
	// of which require IDENTIFIER to be immediately followed by "=" or
	// ";" - a "(" here must fail both and fall back to FUNCTION_DECLARATION.
	input := []Token {
		{type = .KEYWORD, kind = Keyword.INT},
		{type = .IDENTIFIER},
		{type = .DELIMITER, kind = Delimiter.PAREN_OPEN},
		{type = .DELIMITER, kind = Delimiter.PAREN_CLOSE},
		{type = .DELIMITER, kind = Delimiter.BRACE_OPEN},
		{type = .KEYWORD, kind = Keyword.INT}, // body: "int x;" (mandatory)
		{type = .IDENTIFIER},
		{type = .DELIMITER, kind = Delimiter.SEMICOLUMN},
		{type = .DELIMITER, kind = Delimiter.BRACE_CLOSE},
	}

	root, remaining, err := parse_production(.DECLS, input)

	testing.expect(t, err == .OK)
	testing.expect_value(t, len(remaining), 0)

	c_fndecl, _ := count_labeled(&root, .FUNCTION_DECLARATION)
	c_decl, _ := count_labeled(&root, .DECLARATION)
	c_decl_assign, _ := count_labeled(&root, .DECLARATION_WITH_ASSIGNMENT)
	testing.expect_value(t, c_fndecl, 1)
	// the body statement ("int x;") is itself a nested DECLARATION
	testing.expect_value(t, c_decl, 1)
	testing.expect_value(t, c_decl_assign, 0)
	free_all()
}
