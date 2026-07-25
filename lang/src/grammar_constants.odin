package langlang

// Production = name "=" Expression
// Expression = Alternative { "|", Alternative }
// Alternative = Term { Term }
// Term = name | Token | Group | Option | Repetition
// Group = "(" Expression ")" // dla każdej możliwości tworzy nowe pod drzewo
// Option = "[" Expression "]" // tworzy możliwość dla wartości opcji oraz dla jej braku
// Repetition = "{" Expression "}" // tworzy możliwość dla wartości opcji oraz dla jej braku oraz dla wartości tworzy kontynuację z tą opcjąć

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
Group :: distinct []union {
	Expression,
	ProductionName,
}

// Can hold one or zero expressions
// Use of []Expr is unfortunate and doesn't reflect well the data type but it mitigates recursive struct inclusion problem
Option :: distinct []union {
	Expression,
	ProductionName,
}


// Can hold zero or many expression
Repetition :: distinct []union {
	Expression,
	ProductionName,
}

ProductionName :: enum {
	DECLS,
	DECLARATION,
	DECLARATION_WITH_ASSIGNMENT,
	TYPES,
	DECIMAL_TYPE,
	FLOAT_TYPE,
	TEXT_TYPE,
	CHARACTER_TYPE,
	LITERALS,
	DECIMAL_LITERAL,
	FLOAT_LITERAL,
	TEXT_LITERAL,
	CHARACTER_LITERAL,
}

Productions: [ProductionName]Production = {
	.CHARACTER_LITERAL = Production {
		name = .CHARACTER_LITERAL,
		expression = Expression {
			alternative = Alternative {
				term = Term{value = Token{type = .KEYWORD, kind = Keyword.CHAR}},
				terms = {},
			},
			alternatives = Repetition{},
		},
	},
	.DECIMAL_LITERAL = Production {
		name = .DECIMAL_LITERAL,
		expression = Expression {
			alternative = Alternative {
				term = Term{value = Token{type = .KEYWORD, kind = Keyword.INT}},
				terms = {},
			},
			alternatives = Repetition{},
		},
	},
	.FLOAT_LITERAL = Production {
		name = .FLOAT_LITERAL,
		expression = Expression {
			alternative = Alternative {
				term = Term{value = Token{type = .KEYWORD, kind = Keyword.FLOAT}},
				terms = {},
			},
			alternatives = Repetition{},
		},
	},
	.TEXT_LITERAL = Production {
		name = .TEXT_LITERAL,
		expression = Expression {
			alternative = Alternative {
				term = Term{value = Token{type = .KEYWORD, kind = Keyword.STRING}},
				terms = {},
			},
			alternatives = Repetition{},
		},
	},
	.LITERALS = Production {
		name = .LITERALS,
		expression = Expression {
			alternative = Alternative{term = Term{ProductionName.DECIMAL_LITERAL}, terms = {}},
			alternatives = Repetition {
				ProductionName.CHARACTER_LITERAL,
				ProductionName.FLOAT_LITERAL,
				ProductionName.TEXT_LITERAL,
			},
		},
	},
	.CHARACTER_TYPE = Production {
		name = .CHARACTER_TYPE,
		expression = Expression {
			alternative = Alternative {
				term = Term{value = Token{type = .KEYWORD, kind = Keyword.CHAR}},
				terms = {},
			},
			alternatives = Repetition{},
		},
	},
	.DECIMAL_TYPE = Production {
		name = .DECIMAL_TYPE,
		expression = Expression {
			alternative = Alternative {
				term = Term{value = Token{type = .KEYWORD, kind = Keyword.INT}},
				terms = {},
			},
			alternatives = Repetition{},
		},
	},
	.FLOAT_TYPE = Production {
		name = .FLOAT_TYPE,
		expression = Expression {
			alternative = Alternative {
				term = Term{value = Token{type = .KEYWORD, kind = Keyword.FLOAT}},
				terms = {},
			},
			alternatives = Repetition{},
		},
	},
	.TEXT_TYPE = Production {
		name = .TEXT_TYPE,
		expression = Expression {
			alternative = Alternative {
				term = Term{value = Token{type = .KEYWORD, kind = Keyword.STRING}},
				terms = {},
			},
			alternatives = Repetition{},
		},
	},
	.TYPES = Production {
		name = .TYPES,
		expression = Expression {
			alternative = Alternative{term = Term{ProductionName.DECIMAL_TYPE}, terms = {}},
			alternatives = Repetition {
				ProductionName.CHARACTER_TYPE,
				ProductionName.FLOAT_TYPE,
				ProductionName.TEXT_TYPE,
			},
		},
	},
	.DECLARATION = Production {
		name = .DECLARATION,
		expression = Expression {
			alternative = Alternative {
				term = Term{ProductionName.TYPES},
				terms = {
					Expression {
						alternative = Alternative {
							term = Term{value = Token{type = .IDENTIFIER}},
							terms = {},
						},
						alternatives = Repetition{},
					},
					Expression {
						alternative = Alternative {
							term = Term {
								value = Token{type = .DELIMITER, kind = Delimiter.SEMICOLUMN},
							},
							terms = {},
						},
						alternatives = Repetition{},
					},
				},
			},
			alternatives = Repetition{},
		},
	},
	.DECLARATION_WITH_ASSIGNMENT = Production {
		name = .DECLARATION_WITH_ASSIGNMENT,
		expression = Expression {
			alternative = Alternative {
				term = Term{ProductionName.TYPES},
				terms = {
					Expression {
						alternative = Alternative {
							term = Term{value = Token{type = .IDENTIFIER}},
							terms = {},
						},
						alternatives = Repetition{},
					},
					Expression {
						alternative = Alternative {
							term = Term{value = Token{type = .OPERATOR, kind = Operator.EQUAL}},
							terms = {},
						},
						alternatives = Repetition{},
					},
					Expression {
						alternative = Alternative {
							term = Term{value = ProductionName.LITERALS},
							terms = {},
						},
						alternatives = Repetition{},
					},
					Expression {
						alternative = Alternative {
							term = Term {
								value = Token{type = .DELIMITER, kind = Delimiter.SEMICOLUMN},
							},
							terms = {},
						},
						alternatives = Repetition{},
					},
				},
			},
			alternatives = Repetition{},
		},
	},
	.DECLS = Production {
		name = .DECLS,
		expression = Expression {
			alternative = Alternative{term = Term{ProductionName.DECLARATION}, terms = {}},
			alternatives = Repetition{ProductionName.DECLARATION_WITH_ASSIGNMENT},
		},
	},
}
