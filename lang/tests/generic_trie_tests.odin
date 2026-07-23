package tests

import lang "../src"
import "core:testing"

Node_AppendChild :: lang.TrieNode_AppendChild
Node_Contains :: lang.TrieNode_Contains
Node_FetchChild :: lang.TrieNode_FetchChild
Node_Delete :: lang.TrieNode_Delete

Trie_Contains :: lang.Trie_Contains
Trie_Delete :: lang.Trie_Delete
Trie_AppendWord :: lang.Trie_AppendWord
Trie_Initialize :: lang.Trie_Initialize

TrieInt :: lang.Trie(int)
NodeInt :: lang.TrieNode(int)

exp :: testing.expect

@(test)
Node_Contains_nil_test :: proc(t: ^testing.T) {
	testing.expect_assert(t, "nilptr")
	Node_Contains(int, nil, 9)
}


@(test)
Node_Contains_test :: proc(t: ^testing.T) {
	n := NodeInt{}
	append(
		&n.children,
		NodeInt{value = 1},
		NodeInt{value = 3},
		NodeInt{value = 5},
		NodeInt{value = 7},
		NodeInt{value = 9},
	)

	for i in 0 ..< 20 {
		ok, idx := Node_Contains(int, &n, i)
		if i % 2 == 1 && i <= 9 {
			exp(t, ok)
			exp(t, idx == i / 2)
		} else {
			exp(t, !ok)
		}
	}

	Node_Delete(int, &n)
}

@(test)
Node_AppendChild_nil_test :: proc(t: ^testing.T) {
	testing.expect_assert(t, "nilptr")
	_, err := Node_AppendChild(int, nil, false, 1)
}

@(test)
Node_AppendChild_test :: proc(t: ^testing.T) {
	n := NodeInt{}
	defer Node_Delete(int, &n)

	for i in 0 ..< 8 {
		idx, err := Node_AppendChild(int, &n, false, i)
		exp(t, err == .OK)
		exp(t, idx == i)
	}
	exp(t, len(n.children) == 8)

	for i in 0 ..< 8 {
		idx, err := Node_AppendChild(int, &n, false, i)
		exp(t, err == .ALREADY_EXISTS)
		exp(t, idx == i)
	}
	exp(t, len(n.children) == 8)

	// c := context

	// context.allocator = out_of_memory_allocator()

	c := n.children.allocator
	n.children.allocator = out_of_memory_allocator()
	for i in 0 ..< 8 {
		idx, err := Node_AppendChild(int, &n, false, i)
		exp(t, err == .ALREADY_EXISTS)
		exp(t, idx == i)
	}
	exp(t, len(n.children) == 8)
	for i in 8 ..< 11 {
		idx, err := Node_AppendChild(int, &n, false, i)
		exp(t, err == .ALLOCATION_ERROR)
	}
	exp(t, len(n.children) == 8)

	n.children.allocator = c

	for i in 8 ..< 11 {
		idx, err := Node_AppendChild(int, &n, false, i)
		exp(t, err == .OK)
		exp(t, idx == i)
	}
	exp(t, len(n.children) == 11)
	for i in 8 ..< 11 {
		idx, err := Node_AppendChild(int, &n, false, i)
		exp(t, err == .ALREADY_EXISTS)
		exp(t, idx == i)
	}
	exp(t, len(n.children) == 11)
}

@(test)
Node_FetchChild_nil_test :: proc(t: ^testing.T) {
	testing.expect_assert(t, "nilptr")
	Node_FetchChild(int, nil, 1)
}

@(test)
Node_FetchChild_test :: proc(t: ^testing.T) {

	n := NodeInt{}
	defer Node_Delete(int, &n)
	for i in 0 ..< 5 {
		idx, err := Node_AppendChild(int, &n, false, i)
		exp(t, err == .OK)
		exp(t, idx == i)
	}

	for i in 0 ..< 10 {
		ptr, err := Node_FetchChild(int, &n, i)
		if i < 5 {
			exp(t, err == .OK)
			exp(t, ptr != nil)
		} else {
			exp(t, err == .CHILD_DOES_NOT_EXIST)
		}
	}
}

@(test)
Node_Delete_nil_test :: proc(t: ^testing.T) {
	testing.expect_assert(t, "nilptr")
	Node_Delete(int, nil)
}

@(test)
Node_Delete_test :: proc(t: ^testing.T) {
	n0 := NodeInt {
		value = 0,
	}
	defer Node_Delete(int, &n0)

	for i in 0 ..< 3 {
		_, err := Node_AppendChild(int, &n0, false, i)
		exp(t, err == .OK)
	}

	for i in 0 ..< len(n0.children) {
		node, err := Node_FetchChild(int, &n0.children[i], i)
		exp(t, err == .CHILD_DOES_NOT_EXIST)

		idx, e := Node_AppendChild(int, &n0.children[i], false, i)
		exp(t, e == .OK)
		exp(t, idx == 0)

		node, err = Node_FetchChild(int, &n0.children[i], i)
		exp(t, err == .OK)
		exp(t, node != nil)
	}

	for v, i in n0.children {
		exp(t, v.value == i)
		exp(t, len(v.children) == 1)

		exp(t, len(n0.children[i].children) == 1)
		Node_Delete(int, &n0.children[i])
		exp(t, len(n0.children[i].children) == 0)
	}

}

@(test)
Trie_Initialize_test :: proc(t: ^testing.T) {
	trie := Trie_Initialize(int)

	exp(t, trie.size == 0)
	exp(t, len(trie.root.children) == 0)
}


@(test)
Trie_AppendWord_nil_test1 :: proc(t: ^testing.T) {
	word := []int{1, 2, 3}
	trie := Trie_Initialize(int)

	empty: []int
	testing.expect_assert(t, "nilptr")
	Trie_AppendWord(int, nil, word)
}
@(test)
Trie_AppendWord_nil_test2 :: proc(t: ^testing.T) {
	word := []int{1, 2, 3}
	trie := Trie_Initialize(int)

	empty: []int
	testing.expect_assert(t, "nilptr")
	Trie_AppendWord(int, &trie, []int{})
}
@(test)
Trie_AppendWord_nil_test3 :: proc(t: ^testing.T) {
	word := []int{1, 2, 3}
	trie := Trie_Initialize(int)

	empty: []int
	testing.expect_assert(t, "nilptr")
	Trie_AppendWord(int, &trie, empty)
}
@(test)
Trie_AppendWord_nil_test4 :: proc(t: ^testing.T) {
	word := []int{1, 2, 3}
	trie := Trie_Initialize(int)

	empty: []int
	testing.expect_assert(t, "nilptr")
	Trie_AppendWord(int, &trie, nil)
}


@(test)
Trie_AppendWord_test :: proc(t: ^testing.T) {
	word := []int{1, 2, 3}
	trie := Trie_Initialize(int)

	defer Trie_Delete(int, &trie)
	exp(t, trie.size == 0)

	err := Trie_AppendWord(int, &trie, word)
	exp(t, trie.size == 3)
	exp(t, err == .OK)

	err = Trie_AppendWord(int, &trie, []int{3, 2, 1})
	exp(t, trie.size == 6)
	exp(t, err == .OK)

	err = Trie_AppendWord(int, &trie, []int{3, 2, 2})
	exp(t, trie.size == 7)
	exp(t, err == .OK)

	err = Trie_AppendWord(int, &trie, []int{3, 2, 2, 2, 3})
	exp(t, trie.size == 9)
	exp(t, err == .OK)

	err = Trie_AppendWord(int, &trie, []int{3, 2, 2})
	exp(t, trie.size == 9)
	exp(t, err == .ALREADY_EXISTS)

	err = Trie_AppendWord(int, &trie, []int{3, 2, 2, 2})
	exp(t, trie.size == 9)
	exp(t, err == .OK)

	err = Trie_AppendWord(int, &trie, []int{3, 2, 2, 2, 3})
	exp(t, trie.size == 9)
	exp(t, err == .ALREADY_EXISTS)

	for i in 0 ..< 5 {
		err = Trie_AppendWord(int, &trie, []int{4, i})
		exp(t, trie.size == 9 + 2 + i)
		exp(t, err == .OK)
	}

	for i in 0 ..< 5 {
		err = Trie_AppendWord(int, &trie, []int{4, i})
		exp(t, trie.size == 15)
		exp(t, err == .ALREADY_EXISTS)
	}
}

@(test)
Trie_Contains_nil_test1 :: proc(t: ^testing.T) {
	word := []int{1, 2, 3}
	trie := Trie_Initialize(int)

	empty: []int
	testing.expect_assert(t, "nilptr")
	Trie_Contains(int, nil, nil)
}
@(test)
Trie_Contains_nil_test2 :: proc(t: ^testing.T) {
	word := []int{1, 2, 3}
	trie := Trie_Initialize(int)

	empty: []int
	testing.expect_assert(t, "nilptr")
	Trie_Contains(int, &trie, nil)
}
@(test)
Trie_Contains_nil_test3 :: proc(t: ^testing.T) {
	word := []int{1, 2, 3}
	trie := Trie_Initialize(int)

	empty: []int
	testing.expect_assert(t, "nilptr")
	Trie_Contains(int, &trie, empty)
}
@(test)
Trie_Contains_nil_test4 :: proc(t: ^testing.T) {
	word := []int{1, 2, 3}
	trie := Trie_Initialize(int)

	empty: []int
	testing.expect_assert(t, "nilptr")
	Trie_Contains(int, &trie, word)
}


@(test)
Trie_Contains_test :: proc(t: ^testing.T) {
	word := []int{1, 2, 3}
	trie := Trie_Initialize(int)
	defer Trie_Delete(int, &trie)

	exp(t, !Trie_Contains(int, &trie, word))
	Trie_AppendWord(int, &trie, word)
	exp(t, Trie_Contains(int, &trie, word))

	exp(t, !Trie_Contains(int, &trie, []int{1, 2, 3, 4}))
	exp(t, !Trie_Contains(int, &trie, []int{1, 2, 3, 4, 5}))
	exp(t, !Trie_Contains(int, &trie, []int{1, 2, 3, 4, 5, 6}))
	Trie_AppendWord(int, &trie, []int{1, 2, 3, 4})
	exp(t, Trie_Contains(int, &trie, []int{1, 2, 3, 4}))
	exp(t, !Trie_Contains(int, &trie, []int{1, 2, 3, 4, 5}))
	exp(t, !Trie_Contains(int, &trie, []int{1, 2, 3, 4, 5, 6}))
	Trie_AppendWord(int, &trie, []int{1, 2, 3, 4, 5, 6})
	exp(t, Trie_Contains(int, &trie, []int{1, 2, 3, 4}))
	exp(t, !Trie_Contains(int, &trie, []int{1, 2, 3, 4, 5}))
	exp(t, Trie_Contains(int, &trie, []int{1, 2, 3, 4, 5, 6}))
	Trie_AppendWord(int, &trie, []int{1, 2, 3, 4, 5})
	exp(t, Trie_Contains(int, &trie, []int{1, 2, 3, 4}))
	exp(t, Trie_Contains(int, &trie, []int{1, 2, 3, 4, 5}))
	exp(t, Trie_Contains(int, &trie, []int{1, 2, 3, 4, 5, 6}))

}
