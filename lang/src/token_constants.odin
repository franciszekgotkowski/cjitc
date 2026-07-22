package langlang

// declare x int;
// declare x function;
//
// x = a + b;
// x = a - b;
// x = a * b;
// x = a / b;
// x = 11;
// x = 1.2
//
// f(...,...) {...}
// x = f;
// x = f(...);
// return x;
//
// if a < b {...}
// if a > b {...}
// if a <= b {...}
// if a >= b {...}
// if a == b {...}

Digit: []rune : {'0', '1', '2', '3', '4', '5', '6', '7', '8', '9'}
Omitable: []rune : {' ', '\n', '\t', '\r', '\b', '\f'}
LiteralTextSeparator: rune : '"'
LiteralCharSeparator: rune : '\''

TokenType :: enum {
	KEYWORD,
	LITERAL,
	OPERATOR,
	DELIMITER,
	IDENTIFIER,
}

Keyword :: enum {
	INT,
	FLOAT,
	CHAR,
	STRING,
	FUNCTION,
	DECLARE,
	RETURN,
	IF,
}

Operator :: enum {
	LESS,
	MORE,
	LESS_EQUAL,
	MORE_EQUAL,
	EQUAL,
	EQUAL_EQUAL,
	DOT,
	PLUS,
	MINUS,
}

Delimiter :: enum {
	SEMICOLUMN,
	PAREN_OPEN,
	PAREN_CLOSE,
	BRACE_OPEN,
	BRACE_CLOSE,
	COMMA,
}

Literal :: enum {
	DECIMAL,
	TEXT,
	CHARACTER,
}

KeywordValues: [Keyword]string = {
	.INT      = "int",
	.FLOAT    = "float",
	.CHAR     = "char",
	.STRING   = "string",
	.FUNCTION = "function",
	.DECLARE  = "declare",
	.RETURN   = "return",
	.IF       = "if",
}

OperatorValues: [Operator]string = {
	.LESS        = "<",
	.MORE        = ">",
	.LESS_EQUAL  = "<=",
	.MORE_EQUAL  = ">=",
	.EQUAL       = "=",
	.EQUAL_EQUAL = "==",
	.DOT         = ".",
	.PLUS        = "+",
	.MINUS       = "-",
}

DelimiterValues: [Delimiter]string = {
	.SEMICOLUMN  = ";",
	.PAREN_OPEN  = "(",
	.PAREN_CLOSE = ")",
	.BRACE_OPEN  = "{",
	.BRACE_CLOSE = "}",
	.COMMA       = ",",
}

TokenKind :: union {
	Keyword,
	Literal,
	Operator,
	Delimiter,
}
