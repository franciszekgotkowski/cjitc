package langlang

import "core:encoding/json"
import "core:fmt"
import "core:unicode/utf8"

make_tokentree :: proc() -> [dynamic]Token {
	t: [dynamic]Token = {}

	for v, i in TokenType {
		#partial switch v {
		case .KEYWORD:
			for vv, j in Keyword {
				append(
					&t,
					Token{type = v, kind = vv, lexeme = utf8.string_to_runes(KeywordValues[vv])},
				)
			}
		case .OPERATOR:
			for vv, j in Operator {
				append(
					&t,
					Token{type = v, kind = vv, lexeme = utf8.string_to_runes(OperatorValues[vv])},
				)
			}
		case .DELIMITER:
			for vv, j in Delimiter {
				append(
					&t,
					Token{type = v, kind = vv, lexeme = utf8.string_to_runes(DelimiterValues[vv])},
				)
			}
		case:
			continue
		}
	}

	return t
}

main :: proc() {

	trie := Trie_Initialize()

	fmt.println(size_of(Production))

	js, _ := json.marshal(ValueDeclaration, {pretty = true, use_enum_names = true})
	fmt.printfln("%s", js)

	t: [dynamic]Token = make_tokentree()
	defer delete(t)

	for v, i in t {
		Trie_AppendWord(&trie, v.lexeme, v.type, v.kind)
	}

	code: []rune = utf8.string_to_runes("  x=	a+b;ifa<=b{x=a;}")
	// code: []rune = utf8.string_to_runes("s")
	tokens := Tokenise(code, &trie)
	defer delete(tokens)
	js, _ = json.marshal(tokens, {pretty = true, use_enum_names = true})
	fmt.printfln("%s", js)


}
