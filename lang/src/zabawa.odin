package langlang

para :: struct($T: typeid) {
	val: T,
}

para_new :: proc($T: typeid, val: T) -> para(T) {
	return para(T){val}
}

para_check :: proc($T: typeid, ptr: ^para(T), val: T) -> bool {
	return match(ptr.val, val)
}

int_match :: proc(a, b: int) -> bool {
	return a == b
}

float_match :: proc(a, b: f32) -> bool {
	return a == b
}

match :: proc {
	int_match,
	float_match,
}

paraint :: para(int)
