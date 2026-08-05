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
	DECLS,
	DECLARATION,
	DECLARATION_WITH_ASSIGNMENT,
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
	STATEMENT,
	FUNCTION_CALL,
	EXPRESSION,
	ADD_OPERATORS,
	ADD_EXPRESSIONS,
	MUL_OPERATORS,
	MUL_EXPRESSIONS,
	COMP_OPERATORS,
	COMP_EXPRESSIONS,
	UNARY_OPERATORS,
	UNARY_EXPRESSIONS,
	OPERATOR_EXPRESSION,
}

ParseEntryPoint: ProductionName : .CODE_ENTRY

UnrolledProductions: [ProductionName]Maybe(GNode)

Productions: [ProductionName]Production = {
	.CODE_ENTRY                  = {
		Alternative{Repetition{Expression{Alternative{ProductionName.STATEMENT}}}},
	},
	.STATEMENT                   = {
		Alternative{ProductionName.DECLS},
		Alternative{ProductionName.FUNCTION_CALL},
	},
	.DECIMAL_LITERAL             = {Alternative{Token{type = .LITERAL, kind = Literal.DECIMAL}}},
	.CHAR_LITERAL                = {Alternative{Token{type = .LITERAL, kind = Literal.CHARACTER}}},
	.FLOAT_LITERAL               = {
		Alternative {
			Token{type = .LITERAL, kind = Literal.DECIMAL},
			Token{type = .OPERATOR, kind = Operator.DOT},
			Token{type = .LITERAL, kind = Literal.DECIMAL},
		},
	},
	.TEXT_LITERAL                = {Alternative{Token{type = .LITERAL, kind = Literal.TEXT}}},
	.LITERALS                    = {
		Alternative{ProductionName.FLOAT_LITERAL},
		Alternative{ProductionName.CHAR_LITERAL},
		Alternative{ProductionName.DECIMAL_LITERAL},
		Alternative{ProductionName.TEXT_LITERAL},
	},
	.DECIMAL_TYPE                = {Alternative{Token{type = .KEYWORD, kind = Keyword.INT}}},
	.FLOAT_TYPE                  = {Alternative{Token{type = .KEYWORD, kind = Keyword.FLOAT}}},
	.CHARACTER_TYPE              = {Alternative{Token{type = .KEYWORD, kind = Keyword.CHAR}}},
	.TEXT_TYPE                   = {Alternative{Token{type = .KEYWORD, kind = Keyword.STRING}}},
	.TYPES                       = {
		Alternative{ProductionName.DECIMAL_TYPE},
		Alternative{ProductionName.FLOAT_TYPE},
		Alternative{ProductionName.CHARACTER_TYPE},
		Alternative{ProductionName.TEXT_TYPE},
	},
	.DECLARATION_WITH_ASSIGNMENT = {
		Alternative {
			.TYPES,
			Token{type = .IDENTIFIER},
			Token{type = .OPERATOR, kind = Operator.EQUAL},
			.LITERALS,
			Token{type = .DELIMITER, kind = Delimiter.SEMICOLUMN},
		},
	},
	.DECLARATION                 = {
		Alternative {
			.TYPES,
			Token{type = .IDENTIFIER},
			Token{type = .DELIMITER, kind = Delimiter.SEMICOLUMN},
		},
	},
	.DECLS                       = {
		Alternative{ProductionName.DECLARATION_WITH_ASSIGNMENT},
		Alternative{ProductionName.DECLARATION},
	},
	.VARIABLE_NAME               = {Alternative{Token{type = .IDENTIFIER}}},
	.FUNCTION_CALL               = {
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
			Token{type = .DELIMITER, kind = Delimiter.SEMICOLUMN},
		},
	},
	.EXPRESSION                  = {
		Alternative{ProductionName.LITERALS},
		// Alternative{ProductionName.FUNCTION_CALL},
		Alternative{ProductionName.OPERATOR_EXPRESSION},
		Alternative{ProductionName.VARIABLE_NAME},
	},
	.COMP_OPERATORS              = {
		Alternative{Token{type = .OPERATOR, kind = Operator.EQUAL_EQUAL}},
		Alternative{Token{type = .OPERATOR, kind = Operator.NOT_EQUAL}},
		Alternative{Token{type = .OPERATOR, kind = Operator.LESS}},
		Alternative{Token{type = .OPERATOR, kind = Operator.LESS_EQUAL}},
		Alternative{Token{type = .OPERATOR, kind = Operator.MORE}},
		Alternative{Token{type = .OPERATOR, kind = Operator.MORE_EQUAL}},
	},
	.ADD_OPERATORS               = {
		Alternative{Token{type = .OPERATOR, kind = Operator.PLUS}},
		Alternative{Token{type = .OPERATOR, kind = Operator.MINUS}},
		Alternative{Token{type = .OPERATOR, kind = Operator.BITWISE_OR}},
		Alternative{Token{type = .OPERATOR, kind = Operator.BITWISE_NOT}},
	},
	.MUL_OPERATORS               = {
		Alternative{Token{type = .OPERATOR, kind = Operator.MUL}},
		Alternative{Token{type = .OPERATOR, kind = Operator.DIV}},
		Alternative{Token{type = .OPERATOR, kind = Operator.PERCENT}},
		Alternative{Token{type = .OPERATOR, kind = Operator.SHIFT_LEFT}},
		Alternative{Token{type = .OPERATOR, kind = Operator.SHIFT_RIGHT}},
	},
	.UNARY_OPERATORS             = {Alternative{Token{}}},
	.COMP_EXPRESSIONS            = {
		Alternative {
			.ADD_EXPRESSIONS,
			Repetition{Expression{Alternative{.COMP_OPERATORS, .ADD_EXPRESSIONS}}},
		},
	},
	.ADD_EXPRESSIONS             = {
		Alternative {
			.MUL_EXPRESSIONS,
			Repetition{Expression{Alternative{.ADD_OPERATORS, .MUL_EXPRESSIONS}}},
		},
	},
	.MUL_EXPRESSIONS             = {
		Alternative {
			.UNARY_EXPRESSIONS,
			Repetition{Expression{Alternative{.MUL_OPERATORS, .UNARY_EXPRESSIONS}}},
		},
	},
	.UNARY_EXPRESSIONS           = {Alternative{Token{}}},
	.OPERATOR_EXPRESSION         = {Alternative{.COMP_EXPRESSIONS}},
}
