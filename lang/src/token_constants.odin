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

CapitalLetter: []rune = {
	'A',
	'B',
	'C',
	'D',
	'E',
	'F',
	'G',
	'H',
	'I',
	'J',
	'K',
	'L',
	'M',
	'N',
	'O',
	'P',
	'Q',
	'R',
	'S',
	'T',
	'U',
	'V',
	'W',
	'X',
	'Y',
	'Z',
}
Letter: []rune = {
	'a',
	'b',
	'c',
	'd',
	'e',
	'f',
	'g',
	'h',
	'i',
	'j',
	'k',
	'l',
	'm',
	'n',
	'o',
	'p',
	'q',
	'r',
	's',
	't',
	'u',
	'v',
	'w',
	'x',
	'y',
	'z',
}
Underscore: rune : '_'

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
	NOT_EQUAL,
	DOT,
	PLUS,
	MINUS,
	MUL,
	DIV,
	OR,
	AND,
	NOT,
	PERCENT,
	BITWISE_OR,
	BITWISE_NOT,
	BITWISE_AND,
	SHIFT_LEFT,
	SHIFT_RIGHT,
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
	.NOT_EQUAL   = "!=",
	.DOT         = ".",
	.PLUS        = "+",
	.MINUS       = "-",
	.MUL         = "*",
	.DIV         = "/",
	.OR          = "||",
	.AND         = "&&",
	.NOT         = "!",
	.PERCENT     = "%",
	.BITWISE_OR  = "|",
	.BITWISE_NOT = "~",
	.BITWISE_AND = "&",
	.SHIFT_LEFT  = "<<",
	.SHIFT_RIGHT = ">>",
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
