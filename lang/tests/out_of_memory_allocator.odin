
package tests

import "base:runtime"

out_of_memory_allocator_proc :: proc(
	allocator_data: rawptr,
	mode: runtime.Allocator_Mode,
	size, alignment: int,
	old_memory: rawptr,
	old_size: int,
	loc := #caller_location,
) -> (
	[]u8,
	runtime.Allocator_Error,
) {
	switch mode {
	case .Alloc, .Alloc_Non_Zeroed, .Resize, .Resize_Non_Zeroed:
		// Allow zero-sized operations so an empty dynamic array can
		// be initialized with this allocator.
		if size > 0 {
			return nil, .Out_Of_Memory
		}

	case .Free, .Free_All:
	// Nothing was allocated, so freeing is a no-op.

	case .Query_Features:
		features := (^runtime.Allocator_Mode_Set)(old_memory)
		if features != nil {
			features^ = {
				.Alloc,
				.Alloc_Non_Zeroed,
				.Resize,
				.Resize_Non_Zeroed,
				.Free,
				.Free_All,
				.Query_Features,
			}
		}

	case .Query_Info:
		return nil, .Mode_Not_Implemented
	}

	return nil, .None
}

out_of_memory_allocator :: proc() -> runtime.Allocator {
	return runtime.Allocator{procedure = out_of_memory_allocator_proc, data = nil}
}
