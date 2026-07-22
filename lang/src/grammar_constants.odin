package langlang

// Production = name "=" Expression
// Expression = Alternative { "|", Alternative }
// Alternative = Term { Term }
// Term = name | Token | Group | Option | Repetition
// Group = "(" Expression ")"
// Option = "[" Expression "]"
// Repetition = "{" Expression "}"

ProductionName :: enum {
	DECIMAL_DECLARATION,
}
// Allows for Production creation
Production :: struct #all_or_none {
	name:       ProductionName `json:"ProductionName"`,
	expression: Expression `json:"Expression"`,
}
Prod :: Production

// Always returns a value
Expression :: struct #all_or_none {
	alternative:  Alternative `json:"Alternative"`,
	alternatives: Repetition `json:"Alternatives"`,
}
Expr :: Expression

// One of alternative options Expression holds
Alternative :: struct #all_or_none {
	term:  Term `json:"Term"`,
	terms: Repetition `json:"Terms"`,
}
Alt :: Alternative

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
Group :: distinct []Expr

// Can hold one or zero expressions
// Use of []Expr is unfortunate and doesn't reflect well the data type but it mitigates recursive struct inclusion problem
Option :: distinct []Expr
Opt :: Option

// Can hold zero or many expression
Repetition :: distinct []Expr
Rep :: Repetition

ProductionGroup :: []Production
ProdG :: ProductionGroup


Declarations: ProdG = {
	Production {
		name = .DECIMAL_DECLARATION,
		expression = Expression {
			alternative = Alternative {
				term = Term{value = Token{type = .KEYWORD, kind = Keyword.INT}},
				terms = Repetition {
					Expression {
						alternative = Alternative {
							term = Term{value = Token{type = .IDENTIFIER}},
							terms = Repetition{},
						},
						alternatives = {},
					},
					Expression {
						alternative = Alternative {
							term = Term{value = Token{type = .OPERATOR, kind = Operator.EQUAL}},
							terms = {},
						},
						alternatives = {},
					},
					Expression {
						alternative = Alternative {
							term = Term{value = Token{type = .LITERAL, kind = Literal.DECIMAL}},
							terms = {},
						},
						alternatives = {},
					},
				},
			},
			alternatives = {},
		},
	},
}

allGroups: []ProdG = {Declarations}
