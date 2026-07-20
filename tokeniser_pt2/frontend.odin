package main

import "core:encoding/json"
import "core:fmt"
import "core:unicode/utf8"

main :: proc() {

	trie := Trie_Initialize()

	t: [dynamic]Token = {}
	defer delete(t)
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

	for v, i in t {
		Trie_AppendWord(&trie, v.lexeme, v.type, v.kind)
	}
	// json, _ := json.marshal(trie.root, {pretty = true, use_enum_names = true})
	// fmt.printfln("%s", json)

	code: []rune = utf8.string_to_runes("x=a+b;ifa<=b{x=a;}")
	tokens := Tokenise(code, &trie)
	defer delete(tokens)
	json, _ := json.marshal(tokens, {pretty = true, use_enum_names = true})
	fmt.printfln("%s", json)


}
