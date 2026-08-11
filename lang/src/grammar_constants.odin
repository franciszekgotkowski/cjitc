package langlang

// Production = name "=" Expression
// Expression = Alternative { "|", Alternative }
// Alternative = Term { Term }
// Term = name | Token | Group | Option | Repetition
// Group = "(" Expression ")" // dla każdej możliwości tworzy nowe pod drzewo
// Option = "[" Expression "]" // tworzy możliwość dla wartości opcji oraz dla jej braku
// Repetition = "{" Expression "}" // tworzy możliwość dla wartości opcji oraz dla jej braku oraz dla wartości tworzy kontynuację z tą opcjąć


// Will always have Token or DoArray.
// On Initialization it will not have any children
Production :: distinct Expression

// Minimum lenght = 1
// Can have DoArray or Token
Expression :: distinct []Alternative

// Minimum lenght = 1
Alternative :: distinct []Term

Term :: distinct union #no_nil {
	ProductionName,
	Token,
	Group,
	Option,
	Repetition,
}

// Minimum lenght = 1
Group :: distinct []Expression
// Has to have lenght = 1
Option :: distinct []Expression
// Minimum lenght = 1
Repetition :: distinct []Expression

ProductionName :: enum {
	CODE_ENTRY,
	STATEMENT,
	DECLS,
	DECLARATION,
	DECLARATION_WITH_ASSIGNMENT,
	FUNCTION_DECLARATION,
	VARIABLE_NAME,
	TYPES,
	DECIMAL_TYPE,
	FLOAT_TYPE,
	CHARACTER_TYPE,
	TEXT_TYPE,
	LITERALS,
	DECIMAL_LITERAL,
	CHAR_LITERAL,
	FLOAT_LITERAL,
	TEXT_LITERAL,
	FUNCTION_CALL_WITHOUT_RETURNING_VALUES,
	FUNCTION_CALL,
	EXPRESSION,
	MEMBER_ACCESS_EXPRESSION,
	MEMBER_ACCESS_PTR_EXPRESSION,
	ADD_OPERATORS,
	ADD_EXPRESSIONS,
	MUL_OPERATORS,
	MUL_EXPRESSIONS,
	COMP_OPERATORS,
	COMP_EXPRESSIONS,
	PREFIX_OPERATORS,
	UNARY_EXPRESSIONS,
	POSTFIX_OPERATORS,
	OPERATOR_EXPRESSION,
}

ParseEntryPoint: ProductionName : .CODE_ENTRY

UnrolledProductions: [ProductionName]GNode = {}

Productions: [ProductionName]Production = {
	.CODE_ENTRY                             = {
		Alternative{Repetition{Expression{Alternative{ProductionName.STATEMENT}}}},
	},
	.STATEMENT                              = {
		Alternative{ProductionName.DECLS},
		Alternative{ProductionName.FUNCTION_CALL_WITHOUT_RETURNING_VALUES},
	},
	.DECIMAL_LITERAL                        = {
		Alternative{Token{type = .LITERAL, kind = Literal.DECIMAL}},
	},
	.CHAR_LITERAL                           = {
		Alternative{Token{type = .LITERAL, kind = Literal.CHARACTER}},
	},
	.FLOAT_LITERAL                          = {
		Alternative {
			Token{type = .LITERAL, kind = Literal.DECIMAL},
			Token{type = .OPERATOR, kind = Operator.DOT},
			Token{type = .LITERAL, kind = Literal.DECIMAL},
		},
	},
	.TEXT_LITERAL                           = {
		Alternative{Token{type = .LITERAL, kind = Literal.TEXT}},
	},
	.LITERALS                               = {
		Alternative{ProductionName.FLOAT_LITERAL},
		Alternative{ProductionName.CHAR_LITERAL},
		Alternative{ProductionName.DECIMAL_LITERAL},
		Alternative{ProductionName.TEXT_LITERAL},
	},
	.DECIMAL_TYPE                           = {
		Alternative{Token{type = .KEYWORD, kind = Keyword.INT}},
	},
	.FLOAT_TYPE                             = {
		Alternative{Token{type = .KEYWORD, kind = Keyword.FLOAT}},
	},
	.CHARACTER_TYPE                         = {
		Alternative{Token{type = .KEYWORD, kind = Keyword.CHAR}},
	},
	.TEXT_TYPE                              = {
		Alternative{Token{type = .KEYWORD, kind = Keyword.STRING}},
	},
	.TYPES                                  = {
		Alternative{ProductionName.DECIMAL_TYPE},
		Alternative{ProductionName.FLOAT_TYPE},
		Alternative{ProductionName.CHARACTER_TYPE},
		Alternative{ProductionName.TEXT_TYPE},
	},
	.DECLARATION_WITH_ASSIGNMENT            = {
		Alternative {
			.TYPES,
			Token{type = .IDENTIFIER},
			Token{type = .OPERATOR, kind = Operator.EQUAL},
			.EXPRESSION,
			Token{type = .DELIMITER, kind = Delimiter.SEMICOLUMN},
		},
	},
	.DECLARATION                            = {
		Alternative {
			.TYPES,
			Token{type = .IDENTIFIER},
			Token{type = .DELIMITER, kind = Delimiter.SEMICOLUMN},
		},
	},
	.DECLS                                  = {
		Alternative{ProductionName.DECLARATION_WITH_ASSIGNMENT},
		Alternative{ProductionName.DECLARATION},
		Alternative{ProductionName.FUNCTION_DECLARATION},
	},
	.VARIABLE_NAME                          = {Alternative{Token{type = .IDENTIFIER}}},
	.FUNCTION_DECLARATION                   = {
		Alternative {
			ProductionName.TYPES,
			Token{type = .IDENTIFIER},
			Token{type = .DELIMITER, kind = Delimiter.PAREN_OPEN},
			Option {
				Expression {
					Alternative {
						ProductionName.TYPES,
						Token{type = .IDENTIFIER},
						Repetition {
							Expression {
								Alternative {
									Token{type = .DELIMITER, kind = Delimiter.COMMA},
									ProductionName.TYPES,
									Token{type = .IDENTIFIER},
								},
							},
						},
					},
				},
			},
			Token{type = .DELIMITER, kind = Delimiter.PAREN_CLOSE},
			Token{type = .DELIMITER, kind = Delimiter.BRACE_OPEN},
			Repetition{Expression{Alternative{.STATEMENT}}},
			Token{type = .DELIMITER, kind = Delimiter.BRACE_CLOSE},
		},
	},
	.FUNCTION_CALL                          = {
		Alternative {
			Token{type = .IDENTIFIER},
			Token{type = .DELIMITER, kind = Delimiter.PAREN_OPEN},
			Option {
				Expression {
					Alternative {
						ProductionName.EXPRESSION,
						Repetition {
							Expression {
								Alternative{Token{type = .DELIMITER, kind = Delimiter.COMMA}},
							},
							Expression{Alternative{ProductionName.EXPRESSION}},
						},
					},
				},
			},
			Token{type = .DELIMITER, kind = Delimiter.PAREN_CLOSE},
			// Token{type = .DELIMITER, kind = Delimiter.SEMICOLUMN},
		},
	},
	.EXPRESSION                             = {
		Alternative{ProductionName.LITERALS},
		Alternative{ProductionName.FUNCTION_CALL},
		Alternative{ProductionName.OPERATOR_EXPRESSION},
		Alternative{ProductionName.VARIABLE_NAME},
		Alternative{ProductionName.MEMBER_ACCESS_EXPRESSION},
		Alternative{ProductionName.MEMBER_ACCESS_PTR_EXPRESSION},
	},
	.MEMBER_ACCESS_EXPRESSION               = {
		Alternative {
			Token{type = .IDENTIFIER},
			Token{type = .OPERATOR, kind = Operator.DOT},
			Token{type = .IDENTIFIER},
		},
	},
	.MEMBER_ACCESS_PTR_EXPRESSION           = {
		Alternative {
			Token{type = .IDENTIFIER},
			Token{type = .OPERATOR, kind = Operator.RIGHT_ARROW},
			Token{type = .IDENTIFIER},
		},
	},
	.COMP_OPERATORS                         = {
		Alternative{Token{type = .OPERATOR, kind = Operator.EQUAL_EQUAL}},
		Alternative{Token{type = .OPERATOR, kind = Operator.NOT_EQUAL}},
		Alternative{Token{type = .OPERATOR, kind = Operator.LESS}},
		Alternative{Token{type = .OPERATOR, kind = Operator.LESS_EQUAL}},
		Alternative{Token{type = .OPERATOR, kind = Operator.MORE}},
		Alternative{Token{type = .OPERATOR, kind = Operator.MORE_EQUAL}},
	},
	.ADD_OPERATORS                          = {
		Alternative{Token{type = .OPERATOR, kind = Operator.PLUS}},
		Alternative{Token{type = .OPERATOR, kind = Operator.MINUS}},
		Alternative{Token{type = .OPERATOR, kind = Operator.BITWISE_OR}},
		Alternative{Token{type = .OPERATOR, kind = Operator.BITWISE_NOT}},
	},
	.MUL_OPERATORS                          = {
		Alternative{Token{type = .OPERATOR, kind = Operator.MUL}},
		Alternative{Token{type = .OPERATOR, kind = Operator.DIV}},
		Alternative{Token{type = .OPERATOR, kind = Operator.PERCENT}},
		Alternative{Token{type = .OPERATOR, kind = Operator.SHIFT_LEFT}},
		Alternative{Token{type = .OPERATOR, kind = Operator.SHIFT_RIGHT}},
	},
	.PREFIX_OPERATORS                       = {
		Alternative{Token{type = .OPERATOR, kind = Operator.PLUS_PLUS}},
		Alternative{Token{type = .OPERATOR, kind = Operator.MINUS_MINUS}},
		Alternative{Token{type = .OPERATOR, kind = Operator.MUL}},
		Alternative{Token{type = .OPERATOR, kind = Operator.AND}},
		Alternative{Token{type = .OPERATOR, kind = Operator.NOT}},
		Alternative{Token{type = .OPERATOR, kind = Operator.BITWISE_NOT}},
		Alternative{Token{type = .OPERATOR, kind = Operator.MINUS}},
	},
	.POSTFIX_OPERATORS                      = {
		Alternative{Token{type = .OPERATOR, kind = Operator.PLUS_PLUS}},
		Alternative{Token{type = .OPERATOR, kind = Operator.MINUS_MINUS}},
		Alternative{Token{type = .OPERATOR, kind = Operator.MUL}},
	},
	.COMP_EXPRESSIONS                       = {
		Alternative {
			.ADD_EXPRESSIONS,
			Repetition{Expression{Alternative{.COMP_OPERATORS, .ADD_EXPRESSIONS}}},
		},
	},
	.ADD_EXPRESSIONS                        = {
		Alternative {
			.MUL_EXPRESSIONS,
			Repetition{Expression{Alternative{.ADD_OPERATORS, .MUL_EXPRESSIONS}}},
		},
	},
	.MUL_EXPRESSIONS                        = {
		Alternative {
			.UNARY_EXPRESSIONS,
			Repetition{Expression{Alternative{.MUL_OPERATORS, .UNARY_EXPRESSIONS}}},
		},
	},
	.UNARY_EXPRESSIONS                      = {
		Alternative {
			.PREFIX_OPERATORS,
			Group {
				Expression{Alternative{Token{type = .LITERAL}}},
				Expression{Alternative{Token{type = .IDENTIFIER}}},
			},
		},
		Alternative {
			Group {
				Expression{Alternative{Token{type = .LITERAL}}},
				Expression{Alternative{Token{type = .IDENTIFIER}}},
			},
			.POSTFIX_OPERATORS,
		},
		Alternative {
			Group {
				Expression{Alternative{Token{type = .LITERAL}}},
				Expression{Alternative{Token{type = .IDENTIFIER}}},
			},
		},
	},
	.OPERATOR_EXPRESSION                    = {Alternative{.COMP_EXPRESSIONS}},
	.FUNCTION_CALL_WITHOUT_RETURNING_VALUES = {
		Alternative{.FUNCTION_CALL, Token{type = .DELIMITER, kind = Delimiter.SEMICOLUMN}},
	},
}
