package langlang

import "base:runtime"
import "core:encoding/json"
import "core:fmt"
import "core:mem"
import "core:unicode/utf8"

make_token_array :: proc() -> [dynamic]Token {
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

make_token_trie :: proc() -> Trie(RuneWithToken) {
	token_array: [dynamic]Token = make_token_array()
	defer {
		for v, i in token_array {
			delete(token_array[i].lexeme)
		}
		delete(token_array)
	}

	arr: [dynamic][dynamic]RuneWithToken
	defer {
		for v, i in arr {
			delete(arr[i])
		}
		delete(arr)
	}
	for v, i in token_array {
		append(&arr, RuneWithTokenArr(v))
	}

	trie := Trie_Initialize(RuneWithToken)
	for v, i in arr {
		err := Trie_AppendWord(RuneWithToken, &trie, arr[i][:])
		assert(err == .OK)
	}
	return trie
}

RuneWithToken :: struct {
	rune:  rune,
	token: Maybe(Token),
}

RuneWithToken_Match :: proc(a, b: RuneWithToken) -> bool {
	return a.rune == b.rune

	// av, aok := a.token.?
	// bv, bok := b.token.?

	// if aok != bok do return false

	// if aok == false && bok == false {
	// return a.rune == b.rune
	// } else {
	// return match(av, bv)
	// }
}

RuneWithTokenArr :: proc(token: Token) -> [dynamic]RuneWithToken {
	arr: [dynamic]RuneWithToken

	for v, i in token.lexeme {
		append(&arr, RuneWithToken{v, i == len(token.lexeme) - 1 ? token : {}})
	}

	return arr
}

main :: proc() {

	trie := make_token_trie()

	// js, _ := json.marshal(trie, json.Marshal_Options{pretty = true, use_enum_names = true})
	// fmt.printfln("%s", js)

	// code: []rune = utf8.string_to_runes("  x=	a+b;ifa<=b{x=a;}")
	// code: []rune = utf8.string_to_runes(
	// 	`
	// 	int x;
	// 	int xxx = 2;
	// 	float f = 3.4;
	// 	func(4, 5, 1.2);
	// 	float fl = 3;
	// 	`,
	// )
	code: []rune = utf8.string_to_runes(
		"float f = 5.0; func(); funx(4.5); fu(3); fu(4, 4.4); fu(4, 4.4, 'd'); fu(4, 4.4, 'd', 8); fu(4, 4.4, 'd', 8, 4.4);",
	)
	// code: []rune = utf8.string_to_runes("float f = 5;")
	tokens := Tokenise(code, &trie)
	defer delete(tokens)
	// js, _ := json.marshal(tokens, {pretty = true, use_enum_names = true})
	// fmt.printfln("%s", js)

	alloc: runtime.Allocator = context.allocator
	arena: mem.Dynamic_Arena

	mem.dynamic_arena_init(&arena)
	context.allocator = mem.dynamic_arena_allocator(&arena)

	defer {
		mem.dynamic_arena_destroy(&arena)
		context.allocator = alloc
	}

	// for v, i in UnrolledProductions {
	// if v == nil {
	// UnrolledProductions[i] = Unroll_Production(Productions[i], i)
	// }
	// }
	// GNode_Print(&UnrolledProductions[ParseEntryPoint].?)
	p: ProductionName = .CODE_ENTRY
	UnrolledProductions[p] = Unroll_Production(Productions[p], p)

	// ParseTokens(PNode{}, &UnrolledProductions[p].?, tokens[:])

	pnode, _, err := ParseTokens(PNode{}, &UnrolledProductions[p].?, tokens[:])
	if err == .OK {
		js, _ := json.marshal(pnode, json.Marshal_Options{pretty = true, use_enum_names = true})
		fmt.printf("%s\n", js)
	}
}
