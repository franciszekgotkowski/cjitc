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
	DECLS,
	DECLARATION,
	DECLARATION_WITH_ASSIGNMENT,
	TYPES,
	DECIMAL_TYPE,
	FLOAT_TYPE,
	// TEXT_TYPE,
	// CHARACTER_TYPE,
	LITERALS,
	DECIMAL_LITERAL,
	CHAR_LITERAL,
	// TEXT_LITERAL,
	// CHARACTER_LITERAL,
}

UnrolledProductions: [ProductionName]Maybe(GNode) = {}

Productions: [ProductionName]Production = {
	.DECIMAL_LITERAL             = {Alternative{Token{type = .LITERAL, kind = Literal.DECIMAL}}},
	.CHAR_LITERAL                = {Alternative{Token{type = .LITERAL, kind = Literal.CHARACTER}}},
	.LITERALS                    = {
		Alternative{ProductionName.DECIMAL_LITERAL, ProductionName.CHAR_LITERAL},
	},
	.DECIMAL_TYPE                = {Alternative{Token{type = .KEYWORD, kind = Keyword.INT}}},
	.FLOAT_TYPE                  = {Alternative{Token{type = .KEYWORD, kind = Keyword.FLOAT}}},
	.TYPES                       = {
		Alternative{ProductionName.DECIMAL_TYPE},
		Alternative{ProductionName.FLOAT_TYPE},
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
		Alternative{ProductionName.DECLARATION},
		Alternative{ProductionName.DECLARATION_WITH_ASSIGNMENT},
	},
}
