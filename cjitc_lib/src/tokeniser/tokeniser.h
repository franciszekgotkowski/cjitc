#pragma once

#include <stdint.h>

#include "../allocator/allocator_interface.h"
#include "tokeniser_error.h"

typedef struct {
	uint32_t type;
	uint32_t id;
} Token ;

typedef struct {
	const char* translationUnit;
	uint32_t fileLen;

	int32_t tokensLifetime;
	Token* tokens;
} Tokeniser;

Tokeniser Tokeniser_Initialize(
	const char* translationUnit,
	uint32_t fileLen,
	cjitc_allocator* allocator,
	TokeniserError* err
);