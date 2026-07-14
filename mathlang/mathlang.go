package main

import (
	"encoding/json"
	"fmt"
)

func Assert(b bool) {
	if b == false {
		panic(fmt.Sprintln("Assertion failed!"))
	}
}

// Język będzie brał rune jako input i produkował inne rune'y
// S -> +ab
// S -> -ab
// S -> *ab
// S -> /ab

type terminalType int

const (
	ADD terminalType = iota
	SUB
	MUL
	DIV
	NONTERMINAL

	UNKNOWN
)

func (t terminalType) ToString() string {
	switch t {
	case ADD:
		return "ADD"
	case SUB:
		return "SUB"
	case MUL:
		return "MUL"
	case DIV:
		return "DIV"
	case NONTERMINAL:
		return "NONTERMINAL"
	default:
		return "UNKNOWN"
	}
}

func IdentifyTerminalType(r rune) terminalType {
	switch r {
	case '+':
		return ADD
	case '-':
		return SUB
	case '*':
		return MUL
	case '/':
		return DIV
	default:
		return NONTERMINAL
	}
}

func (t terminalType) ToRune() rune {
	switch t {
	case ADD:
		return '+'
	case SUB:
		return '-'
	case MUL:
		return '*'
	case DIV:
		return '/'
	default:
		return ' '
	}
}

type Token struct {
	T terminalType `json:"terminal type"`
	V rune         `json:"rune"`

	A *Token `json:"token a"`
	B *Token `json:"token b"`
}

func NewToken(
	t terminalType,
	v rune,
	a *Token,
	b *Token,
) Token {
	var tok Token = Token{
		t,
		v,
		a,
		b,
	}
	if a == nil || b == nil {
		Assert(t == NONTERMINAL)
	}
	return tok
}

func (T Token) ToString() string {

	str, err := json.MarshalIndent(T, "", "\t")
	if err != nil {
		fmt.Println(err.Error())
		return ""
	} else {
		return string(str)
	}

}

func ParseCode(code []rune) *Token {
	defer func() {
		if r := recover(); r != nil {
			fmt.Println(string(code))
			fmt.Printf("Parsing error: %s", r)
			fmt.Println()
		}
	}()
	root, parsedLen := parse(code)

	if parsedLen > uint32(len(code)) {
		fmt.Println(string(code))
		fmt.Println("Parsing error: Too many expressions")
		fmt.Println()
		return nil
	} else if parsedLen < uint32(len(code)) {
		fmt.Println(string(code))
		fmt.Println("Parsing error: Too little expressions")
		fmt.Println()
		return nil
	} else {
		return root
	}

}

// *Token - token it produces
func parse(code []rune) (*Token, uint32) {

	var sum uint32 = 0

	defer func() {
		if r := recover(); r != nil {
			panic(r)
		}
	}()
	if len(code) == 0 {
		panic(fmt.Sprintf("Terminal does not have enaugh nonterminals\n"))
	}

	token := Token{}

	sum += 1

	token.T = IdentifyTerminalType(code[0])
	if token.T == NONTERMINAL {
		token.A = nil
		token.B = nil
		token.V = code[0]

		return &token, sum
	}

	var l uint32
	token.A, l = parse(code[1:])
	sum += l
	token.B, l = parse(code[1+l:])
	sum += l

	return &token, sum
}

func rec(r []rune) {
	if len(r) > 0 {
		fmt.Println(string(r))
		rec(r[1:])
	}
}

func (token Token) Execute(b bool) rune {
	var s string

	if token.T == NONTERMINAL {
		return token.V
	} else {
		switch token.T {
		case ADD:
			r := token.A.Execute(true) + token.B.Execute(true)
			if b {
				s = fmt.Sprintf("%d + %d = %d", token.A.Execute(false), token.B.Execute(false), token.A.Execute(false)+token.B.Execute(false))
				fmt.Println(s)
			}
			return r
		case SUB:
			r := token.A.Execute(true) - token.B.Execute(true)
			if b {
				s = fmt.Sprintf("%d - %d = %d", token.A.Execute(false), token.B.Execute(false), token.A.Execute(false)-token.B.Execute(false))
				fmt.Println(s)
			}
			return r
		case MUL:
			r := token.A.Execute(true) * token.B.Execute(true)
			if b {
				s = fmt.Sprintf("%d * %d = %d", token.A.Execute(false), token.B.Execute(false), token.A.Execute(false)*token.B.Execute(false))
				fmt.Println(s)
			}
			return r
		case DIV:
			r := token.A.Execute(true) / token.B.Execute(true)
			if b {
				s = fmt.Sprintf("%d / %d = %d", token.A.Execute(false), token.B.Execute(false), token.A.Execute(false)/token.B.Execute(false))
				fmt.Println(s)
			}
			return r
		default:
			panic("INVALID TERMINAL")
		}
	}
}

func TranslateToInfix(s string) (string, error) {
	var root *Token = ParseCode([]rune(s))
	var inf []rune = make([]rune, len(s))
	if root == nil {
		return "", fmt.Errorf("Cound not parse string")
	}

	toInfix(root, inf, 0)
	return string(inf), nil
}

func toInfix(token *Token, r []rune, idx uint32) {
	var myIdx uint32 = idx
	var ru rune = token.V
	if token.T != NONTERMINAL {
		myIdx = idx + 1
		r[myIdx] = rune(IdentifyTerminalType(token.V))
		toInfix(token.A, r, myIdx-1)
		toInfix(token.B, r, myIdx+1)
		ru = token.T.ToRune()
	}
	r[myIdx] = ru
	// fmt.Println("infix: ", string(r))
}

func main() {

	code1 := []rune("+ab")
	t1 := ParseCode(code1)
	if t1 != nil {
		fmt.Println(t1.ToString())
	}
	fmt.Println(t1.Execute(true))
	s, _ := TranslateToInfix(string(code1))
	fmt.Println(s)

	code2 := []rune("+b-ca")
	t2 := ParseCode(code2)
	if t2 != nil {
		fmt.Println(t2.ToString())
	}
	fmt.Println(t2.Execute(true))
	s, _ = TranslateToInfix(string(code2))
	fmt.Println(s)

	code3 := []rune("+-ab*ca")
	t3 := ParseCode(code3)
	if t3 != nil {
		fmt.Println(t3.ToString())
	}
	fmt.Println(t3.Execute(true))
	s, _ = TranslateToInfix(string(code2))
	fmt.Println(s)

	code4 := []rune("-ab*ca")
	t4 := ParseCode(code4)
	if t4 != nil {
		fmt.Println(t4.ToString())
	}
	fmt.Println()

	code5 := []rune("--aa-a")
	t5 := ParseCode(code5)
	if t5 != nil {
		fmt.Println(t5.ToString())
	}
	fmt.Println()

	code6 := []rune("")
	t6 := ParseCode(code6)
	if t6 != nil {
		fmt.Println(t6.ToString())
	}
	fmt.Println()

	code7 := []rune("---")
	t7 := ParseCode(code7)
	if t7 != nil {
		fmt.Println(t7.ToString())
	}
	fmt.Println()

	code8 := []rune("asd-f")
	t8 := ParseCode(code8)
	if t8 != nil {
		fmt.Println(t8.ToString())
	}
	fmt.Println()
}
