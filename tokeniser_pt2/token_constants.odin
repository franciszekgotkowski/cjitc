package main

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

Literal :: enum {
	INT,
	FLOAT,
}

Digit: []rune : {'0', '1', '2', '3', '4', '5', '6', '7', '8', '9'}
Ignore: []rune : {' ', '\n', '\t', '\r', '\\', '\b', '\f'}

TokenType :: enum {
	KEYWORD,
	LITERAL,
	OPERATOR,
	DELIMITER,
}

Keyword :: enum {
	INT,
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
}

Delimiter :: enum {
	SEMICOLUMN,
	PAREN_OPEN,
	PAREN_CLOSE,
	BRACE_OPEN,
	BRACE_CLOSE,
	COMMA,
}

KeywordValues: [Keyword]string : {
	.INT = "int",
	.FUNCTION = "function",
	.DECLARE = "declare",
	.RETURN = "return",
	.IF = "if",
}

OperatorValues: [Operator]string : {
	.LESS = "<",
	.MORE = ">",
	.LESS_EQUAL = "<=",
	.MORE_EQUAL = ">=",
	.EQUAL = "=",
	.EQUAL_EQUAL = "==",
	.DOT = ".",
}

DelimiterValues: [Delimiter]string : {
	.SEMICOLUMN = ";",
	.PAREN_OPEN = "(",
	.PAREN_CLOSE = ")",
	.BRACE_OPEN = "{",
	.BRACE_CLOSE = "}",
	.COMMA = ",",
}

TokenKind :: union {
	Keyword,
	Literal,
	Operator,
	Delimiter,
}
