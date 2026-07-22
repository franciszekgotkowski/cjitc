package langlang

// Production = name "=" Expression
// Expression = Alternative { "|", Alternative }
// Alternative = Term { Term }
// Term = name | Token | Group | Option | Repetition
// Group = "(" Expression ")"
// Option = "[" Expression "]"
// Repetition = "{" Expression "}"

ProductionName :: enum {
	DECLARATION,
	DECLARATION_WITH_ASSIGNMENT,
	DECIMAL_TYPE,
	FLOAT_TYPE,
	TEXT_TYPE,
	CHARACTER_TYPE,
	DECIMAL_LITERAL,
	FLOAT_LITERAL,
	TEXT_LITERAL,
	CHARACTER_LITERAL,
}
// Allows for Production creation
Production :: struct #all_or_none {
	name:       ProductionName `json:"ProductionName"`,
	expression: Expression `json:"Expression"`,
}

// Always returns a value
Expression :: struct #all_or_none {
	alternative:  Alternative `json:"Alternative"`,
	alternatives: Repetition `json:"Alternatives"`,
}

// One of alternative options Expression holds
Alternative :: struct #all_or_none {
	term:  Term `json:"Term"`,
	terms: Repetition `json:"Terms"`,
}

// Possible values of Term
// @(private = "file")
TermValue :: union #no_nil {
	ProductionName,
	Token,
	Group,
	Option,
	Repetition,
}
// It holds some value, probably identifier or literal but it does not have to be this way
Term :: struct #all_or_none {
	value: TermValue `json:"Value"`,
}

// Has to hold one expressions from the list of possible expressions.
// For example it could hold one of "+", "-" operator tokens
// Use of []Expr is unfortunate and doesn't reflect well the data type but it mitigates recursive struct inclusion problem
Group :: distinct []ExpressionOrProductionGroup

// Can hold one or zero expressions
// Use of []Expr is unfortunate and doesn't reflect well the data type but it mitigates recursive struct inclusion problem
Option :: distinct []ExpressionOrProductionGroup

// Can hold zero or many expression
Repetition :: distinct []ExpressionOrProductionGroup

ProductionGroup :: []Production

ExpressionOrProductionGroup :: union #no_nil {
	Expression,
	ProductionGroup,
}

Types: ProductionGroup = {
	Production {
		.DECIMAL_TYPE,
		Expression {
			Alternative{Term{Token{type = .KEYWORD, kind = Keyword.INT}}, Repetition{}},
			Repetition{},
		},
	},
	Production {
		.FLOAT_TYPE,
		Expression {
			Alternative{Term{Token{type = .KEYWORD, kind = Keyword.FLOAT}}, Repetition{}},
			Repetition{},
		},
	},
	Production {
		.CHARACTER_TYPE,
		Expression {
			Alternative{Term{Token{type = .KEYWORD, kind = Keyword.CHAR}}, Repetition{}},
			Repetition{},
		},
	},
	Production {
		.TEXT_TYPE,
		Expression {
			Alternative{Term{Token{type = .KEYWORD, kind = Keyword.STRING}}, Repetition{}},
			Repetition{},
		},
	},
}

Literals: ProductionGroup = {
	Production {
		.DECIMAL_LITERAL,
		Expression{Alternative{Term{Token{type = .LITERAL, kind = Literal.DECIMAL}}, {}}, {}},
	},
	Production {
		.FLOAT_LITERAL,
		Expression {
			Alternative {
				Term{Token{type = .LITERAL, kind = Literal.DECIMAL}},
				{
					Expression {
						Alternative{Term{Token{type = .OPERATOR, kind = Operator.DOT}}, {}},
						{},
					},
					Expression {
						Alternative{Term{Token{type = .LITERAL, kind = Literal.DECIMAL}}, {}},
						{},
					},
				},
			},
			{},
		},
	},
	Production {
		.TEXT_LITERAL,
		Expression{Alternative{Term{Token{type = .LITERAL, kind = Literal.TEXT}}, {}}, {}},
	},
	Production {
		.CHARACTER_LITERAL,
		Expression{Alternative{Term{Token{type = .LITERAL, kind = Literal.CHARACTER}}, {}}, {}},
	},
}

ValueDeclaration: ProductionGroup = {
	Production {
		.DECLARATION_WITH_ASSIGNMENT,
		Expression {
			Alternative {
				Term{Repetition{Types}},
				Repetition {
					Expression {
						Alternative {
							term = Term{value = Token{type = .IDENTIFIER}},
							terms = Repetition{},
						},
						{},
					},
					Expression {
						Alternative {
							term = Term{value = Token{type = .OPERATOR, kind = Operator.EQUAL}},
							terms = Repetition{},
						},
						{},
					},
					Literals,
					Expression {
						Alternative {
							Term{value = Token{type = .DELIMITER, kind = Delimiter.SEMICOLUMN}},
							{},
						},
						{},
					},
				},
			},
			{},
		},
	},
	Production {
		.DECLARATION,
		Expression {
			Alternative {
				Term{Repetition{Types}},
				Repetition {
					Expression {
						Alternative {
							term = Term{value = Token{type = .IDENTIFIER}},
							terms = Repetition{},
						},
						{},
					},
					Literals,
					Expression {
						Alternative {
							Term{value = Token{type = .DELIMITER, kind = Delimiter.SEMICOLUMN}},
							{},
						},
						{},
					},
				},
			},
			{},
		},
	},
}

allGroups: []ProductionGroup = {ValueDeclaration}
