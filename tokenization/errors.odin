package tokenization

Expectation_Error :: union {
	Expected_Token,
	Expected_String,
	Expected_End_Marker,
	Expected_One_Of,
}

Expected_Token :: struct {
	expected: Token,
	actual:   Token,
	location: Location,
}

Expected_String :: struct {
	expected: string,
	actual:   string,
	location: Location,
}

Expected_End_Marker :: struct {
    expected: []string,
    location: Location
}

Expected_One_Of :: struct {
    expected: []Token,
    actual: Token,
    location: Location,
}
