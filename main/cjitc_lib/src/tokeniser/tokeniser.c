#include <assert.h>

#include "tokeniser.h"
#include "../allocator/allocator_interface.h"
#include "../allocator/allocator_errors.h"
#include "tokeniser_error.h"

Tokeniser Tokeniser_Initialize(
	const char* translationUnit,
	uint32_t fileLen,
	cjitc_allocator* allocator,
	TokeniserError* err
) {
	assert(translationUnit);
	assert(allocator);

	Tokeniser ret = (Tokeniser){
		.translationUnit = translationUnit,
		.fileLen = fileLen,
		.tokensLifetime = -1
	};

	AllocatorError e;
	void* ptr = Alloc(
		fileLen*sizeof(Token),
		&ret.tokensLifetime,
		allocator,
		&e
	);

	if (e != ALLOCATOR_OK) {
		*err = TOKENISER_ALLOCATOR_ERROR;
		return (Tokeniser){};
	}
	assert(ptr);
	ret.tokens = ptr;

	return ret;
}