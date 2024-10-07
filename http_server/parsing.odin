package http_server

import "core:mem"
import "core:strings"

import "../tokenization"

MAX_HEADERS_LENGTH :: 64 * mem.Kilobyte

Method :: union {
	GET,
	POST,
}

GET :: struct {}
POST :: struct {
	data: []byte,
}

Request :: struct {
	method:   Method,
	path:     string,
	protocol: string,
	headers:  map[string]string,
}

Parse_Request_Error :: union {
	mem.Allocator_Error,
	tokenization.Expectation_Error
}

parse_request :: proc(
	data: []byte,
	allocator := context.allocator,
) -> (
	m: Request,
	error: Parse_Request_Error,
) {
    data_string :=  strings.clone_from_bytes(data, allocator) or_return
    tokenizer := tokenization.tokenizer_create(data_string)
	t := tokenization.tokenizer_expect(&tokenizer, tokenization.Upper_Symbol{}) or_return

	if t.token.(tokenization.Upper_Symbol).value != "GET" {
		error = tokenization.Expectation_Error(
			tokenization.Expected_Token {
				expected = tokenization.Upper_Symbol{value = "GET"},
				actual = t.token,
				location = t.location
			},
		)

		return Request{}, error
	}

	tokenization.tokenizer_skip_any_of()
}
