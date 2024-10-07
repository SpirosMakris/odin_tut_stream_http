package tokenization

import "core:strings"
import "core:log"
import "core:strconv"
import "core:reflect"


Location :: struct {
	line:        int,
	column:      int,
	position:    int, // byte offset in source
	source_file: string,
}

Source_Token :: struct {
	token:    Token,
	location: Location,
}

/*
A mutable structure that keeps track of and allows operations for
looking at, consuming and expecting tokens. Created with: `tokenizer_create`.
*/
Tokenizer :: struct {
	filename: string,
	source:   string,
	index:    int,
	position: int,
	line:     int,
	column:   int,
}

/*
Creates a `Tokenizer` from a given source string.
Use `tokenizer_peek`, `tokenizer_next_token` and `tokenizer_expect` variants
to read tokens from a `Tokenizer`
*/
tokenizer_create :: proc(source: string) -> Tokenizer {
	return Tokenizer{source = source, line = 1}
}


tokenizer_expect :: proc(
	tokenizer: ^Tokenizer,
	expectation: Token,
) -> (
	token: Source_Token,
	error: Expectation_Error,
) {
	start_location := Location {
		position = tokenizer.position,
		line     = tokenizer.line,
		column   = tokenizer.column,
	}

	read_token, _, _ := tokenizer_next_token(tokenizer)

    // @TODO: more

    expectation_typeid := reflect.union_variant_typeid(expectation)
    token_typeid := reflect.union_variant_typeid(read_token.token)

    if expectation_typeid != token_typeid {
        return Source_Token{},
            Expected_Token {
                expected = expectation,
                actual = read_token.token,
                location = start_location,
            }
    }

    return read_token, nil
}

tokenizer_next_token :: proc(
	tokenizer: ^Tokenizer,
) -> (
	source_token: Source_Token,
	index: int,
	ok: bool,
) {
	source_token = Source_Token {
		location = Location {
			position = tokenizer.position,
			line = tokenizer.line,
			column = tokenizer.column,
		},
	}

    if tokenizer.position >= len(tokenizer.source) {
        source_token.token = EOF{}

        return source_token, tokenizer.index, false
    }

    token := current(tokenizer, true)
    current_index := tokenizer.index
    tokenizer.index += 1

    source_token.token = token

    return source_token, current_index, token != nil
}

@(private="file")
current :: proc(tokenizer: ^Tokenizer, modify: bool) -> (token: Token) {
    tokenizer_copy := tokenizer^
    defer if modify {
        tokenizer^ = tokenizer_copy
    }

    if tokenizer_copy.position >= len(tokenizer_copy.source) {
        return EOF{}
    }

    switch tokenizer_copy.source[tokenizer_copy.position] {
        case '#':
            // This is a comment. Find the index of the newline so we can ignore it
            next_newline_index := strings.index(tokenizer_copy.source[tokenizer_copy.position:], "\n")
            if next_newline_index == -1 {
                tokenizer.position = len(tokenizer.source)

                return EOF{}
            }

            tokenizer_copy.position += next_newline_index

            return Comment{}
        
        case ' ':
            tokenizer_copy.position += 1
            tokenizer_copy.column += 1

            return Space{}
        
        case '\r':
            if tokenizer_copy.source[tokenizer_copy.position + 1] == '\n' {
                tokenizer_copy.position += 2
                tokenizer_copy.line += 1
                tokenizer_copy.column = 0

                return Newline{}
            } else {
                log.panicf(
                    "Unexpected carriage return without newline at %v:%v",
                    tokenizer_copy.line,
                    tokenizer_copy.column
                )
            }

        case '\n':
            tokenizer_copy.position += 1
            tokenizer_copy.line += 1
            tokenizer_copy.column = 0
            
            return Newline{}

        case '(':
            tokenizer_copy.position += 1
            tokenizer_copy.column += 1

            return Left_Paren{}

        case ')':
            tokenizer_copy.position += 1
            tokenizer_copy.column += 1

            return Right_Paren{}

        case '[':
            tokenizer_copy.position += 1
            tokenizer_copy.column += 1

            return Left_Square{}

        case ']':
            tokenizer_copy.position += 1
            tokenizer_copy.column += 1

            return Right_Square{}

        case '{':
            tokenizer_copy.position += 1
            tokenizer_copy.column += 1

            return Left_Curly{}

        case '}':
            tokenizer_copy.position += 1
            tokenizer_copy.column += 1

            return Right_Curly{}

        case '<':
            tokenizer_copy.position += 1
            tokenizer_copy.column += 1

            return Left_Angle{}

        case '>':
            tokenizer_copy.position += 1
            tokenizer_copy.column += 1

            return Right_Angle{}
        
        case '^':
            tokenizer_copy.position += 1
            tokenizer_copy.column += 1

            return Caret{}
        
        case '$':
            return read_char(&tokenizer_copy)

        case ':':
            tokenizer_copy.position += 1
            tokenizer_copy.column += 1

            return Colon{}

        case ',':
            tokenizer_copy.position += 1
            tokenizer_copy.column += 1

            return Comma{}

        case '.':
            tokenizer_copy.position += 1
            tokenizer_copy.column += 1

            return Dot{}

        case '-': 
            tokenizer_copy.position += 1
            tokenizer_copy.column += 1

            return Dash{}

        case '/': 
            tokenizer_copy.position += 1
            tokenizer_copy.column += 1

            return Slash{}

        case '?': 
            tokenizer_copy.position += 1
            tokenizer_copy.column += 1

            return QuestionMark{}
            
        case '!': 
            tokenizer_copy.position += 1
            tokenizer_copy.column += 1

            return ExclamationPoint{}

        case '*': 
            tokenizer_copy.position += 1
            tokenizer_copy.column += 1

            return Asterisk{}

        case '0' ..= '9':
            float := read_float(&tokenizer_copy)

            if float != nil {
                return float
            }

            return read_integer(&tokenizer_copy)

        case '"':
            return read_string(&tokenizer_copy, `"`)

        case '\'':
            return read_string(&tokenizer_copy, "'")
        
        case 't', 'f':
            boolean := read_boolean(&tokenizer_copy)
            if boolean != nil {
                return boolean
            }
            fallthrough
        case 'a'..='z':
            return read_lower_symbol(&tokenizer_copy)

        case 'A' ..='Z':
            return read_upper_symbol(&tokenizer_copy)

        case:
            snippet := tokenizer_copy.source[tokenizer_copy.position:]
            if len(snippet) > 64 {
                snippet = snippet[:64]
            }

            log.panicf(
                "Unexpected character '%c' @ %s:%d:%d (snippet: '%s')",
                tokenizer_copy.source[tokenizer_copy.position],
                tokenizer_copy.filename,
                tokenizer_copy.line,
                tokenizer_copy.column,
                snippet
            )
    }

    return nil
}

tokenizer_peek :: proc(tokenizer: ^Tokenizer) -> (token: Token) {
    if tokenizer.index >= len(tokenizer.source) {
        return nil
    }

    return current(tokenizer, false)
}

tokenizer_skip_any_of :: proc(tokenizer: ^Tokenizer, tokens: []Token) {
    match: for {
        token := tokenizer_peek(tokenizer)
        token_tag := reflect.union_variant_typeid(token)
        for t in tokens {
            t_tag := reflect.union_variant_typeid(t)
            if token_tag == t_tag {
                tokenizer_next_token(tokenizer)
                continue
            }
        }

        break match
    }
}

@(private = "file")
read_lower_symbol :: proc(tokenizer: ^Tokenizer) -> (token: Token) {
    start := tokenizer.position
    source := tokenizer.source[start:]

    assert(source[0] >= 'a' && source[0] <= 'z')

    symbol_value := read_until(source, " \t\n()[]{}<>,.:'\"")
    symbol_length := len(symbol_value)

    tokenizer.position += symbol_length
    tokenizer.column += symbol_length

    return Lower_Symbol{value = symbol_value}
}

@(private = "file")
read_upper_symbol :: proc(tokenizer: ^Tokenizer) -> (token: Token) {
    start := tokenizer.position
    source := tokenizer.source[start:]

    assert(source[0] >= 'A' && source[0] <= 'Z')

    symbol_value := read_until(source, " \t\n()[]{}<>,.:'\"")
    symbol_length := len(symbol_value)
    tokenizer.position += symbol_length
    tokenizer.column += symbol_length

    return Upper_Symbol{value = symbol_value}
}

@(private = "file")
read_char :: proc(tokenizer: ^Tokenizer) -> (token: Token) {
    character := tokenizer.source[tokenizer.position]
    assert(character == '$')
    tokenizer.position += 1
    character = tokenizer.source[tokenizer.position]
    tokenizer.position += 1
    tokenizer.column += 2

    return Char{value = character}
}

@(private = "file")
read_float ::proc(tokenizer: ^Tokenizer) -> (token: Token) {
    start := tokenizer.position
    character := tokenizer.source[tokenizer.position]
    has_period := false
    new_position := tokenizer.position

    for new_position < len(tokenizer.source) && character >= '0' && character <= '9' || character == '.' {
        switch character {
            case '0'..= '9':
                new_position += 1
            case '.':
                has_period = true
                new_position += 1
            case:
                break
            
        }

        if new_position >= len(tokenizer.source) {
            break
        }

        character = tokenizer.source[new_position]
    }

    if !has_period {
        return nil
    }

    slice := tokenizer.source[start:new_position]
    float_value, parse_ok := strconv.parse_f64(slice)
    if !parse_ok {
        return nil
    }

    tokenizer.column += len(slice)
    tokenizer.position = new_position
    token = Float {
        value = float_value
    }

    return
}

@(private="file")
read_integer :: proc(tokenizer: ^Tokenizer) -> (token: Token) {
    start := tokenizer.position
    character := tokenizer.source[tokenizer.position]
    is_number := character >= '0' && character <='9'

    if !is_number {
        return nil
    }

    for is_number {
        if tokenizer.position >= len(tokenizer.source) {
            break
        }

        character = tokenizer.source[tokenizer.position]

        switch character {
            case '0'..='9':
                tokenizer.position += 1
            case:
                is_number = false
        }
    }

    slice := tokenizer.source[start:tokenizer.position]
    int_value, parse_ok := strconv.parse_int(slice)
    if !parse_ok{
        log.panicf("Failed to parse integer ('%s') with state: %v", slice, tokenizer)
    }

    tokenizer.column += len(slice)

    return Integer{value = int_value}
}

@(private = "file")
read_string :: proc(tokenizer: ^Tokenizer, quote_characters: string) -> (token: Token) {
    start := tokenizer.position
    character := string(tokenizer.source[tokenizer.position:tokenizer.position + 1])
    if character != quote_characters {
        return nil
    }

    rest_of_string := tokenizer.source[start + 1:]
    end_quote_index := strings.index(rest_of_string, quote_characters)
    if end_quote_index == -1 {
        log.panicf("Failed to find end quote string: %s", rest_of_string)
    }

    string_contents := rest_of_string[:end_quote_index]
    // @NOTE: 2: because we want to skip over the quote in terms of position;
    // we've already read it
    tokenizer.position += end_quote_index + 2
    last_newline_index := strings.last_index(string_contents, "\n")
    if last_newline_index == -1 {
        tokenizer.column += len(string_contents) + 2
    } else {
        tokenizer.line += strings.count(string_contents, "\n")
        tokenizer.column = end_quote_index - last_newline_index
    }

    if quote_characters == "'" {
        return Single_Quoted_String{value=string_contents}
    }

    return String{value=string_contents}
}

@(private = "file")
read_boolean :: proc(tokenizer: ^Tokenizer) -> (token: Token) {
    start := tokenizer.position
    source := tokenizer.source[start:]

    if prefix_matches(source, "true") {
        tokenizer.position += 4
        tokenizer.column += 4

        return Boolean{value=true}
    } else if prefix_matches(source, "false") {
        tokenizer.position += 5
        tokenizer.column += 5

        return Boolean{value=true}
    }

    return nil
}