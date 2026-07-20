package main

import "core:encoding/json"
import "core:fmt"
import "core:unicode/utf8"

main :: proc() {

	r: [][]rune = {
		utf8.string_to_runes("kot"),
		utf8.string_to_runes("koń"),
		utf8.string_to_runes("kolega"),
		utf8.string_to_runes("mamut"),
		utf8.string_to_runes("mama"),
		utf8.string_to_runes("malkontent"),
	}

	m := map[rune]bool{}
	m[' '] = true
	m['\n'] = true
	m['\t'] = true
	m['\r'] = true
	m['\\'] = true
	// m['\'] = true
	// m['\'']; ' = true
	m['\b'] = true
	m['\f'] = true
	m['0'] = true
	m['1'] = true
	m['2'] = true
	m['3'] = true
	m['4'] = true
	m['5'] = true
	m['6'] = true
	m['7'] = true
	m['8'] = true
	m['9'] = true

	s := utf8.string_to_runes("7 2\n9\\1\t4\r08\b3\f6 5\n2\\9\t17\r40 8")

	ile := 0

	for i in 0 ..< 1000000 {
		for v, _ in s {
			if m[v] {
				ile += 1
			}
		}
	}

	// for i in 0 ..< 1000000 {
	// 	for v, i in Digit {
	// 		if s[i] == v {
	// 			ile += 1
	// 		}
	// 	}
	// 	for v, i in Ignore {
	// 		if s[i] == v {
	// 			ile += 1
	// 		}
	// 	}
	// }

	fmt.println(ile)

	// trie := Trie_Initialize()
	// for _, i in r {
	// 	Trie_AppendWord(&trie, r[i])
	// }
	// json, _ := json.marshal(trie.root, {pretty = true, use_enum_names = true})
	// fmt.printfln("%s", json)
}
