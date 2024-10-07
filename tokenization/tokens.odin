package tokenization

Token :: union {
	EOF,
	Newline,
	Tab,
	Space,
	Left_Paren,
	Right_Paren,
	Left_Square,
	Right_Square,
	Left_Curly,
	Right_Curly,
	Left_Angle,
	Right_Angle,
	Caret,
	Colon,
	Comma,
	Dot,
	Underscore,
	Dash,
	Slash,
	QuestionMark,
	ExclamationPoint,
	Asterisk,
	Comment,
	Upper_Symbol,
	Lower_Symbol,
	String,
	Single_Quoted_String,
	Float,
	Integer,
	Char,
	Boolean,
}

EOF :: struct {}
Newline :: struct {}
Tab :: struct {}
Space :: struct {}
Left_Paren :: struct {}
Right_Paren :: struct {}
Left_Square :: struct {}
Right_Square :: struct {}
Left_Curly :: struct {}
Right_Curly :: struct {}
Left_Angle :: struct {}
Right_Angle :: struct {}
Caret :: struct {}
Colon :: struct {}
Comma :: struct {}
Dot :: struct {}
Underscore :: struct {}
Dash :: struct {}
Slash :: struct {}
QuestionMark :: struct {}
ExclamationPoint :: struct {}
Asterisk :: struct {}
Comment :: struct {}

Upper_Symbol :: struct {
	value: string,
}

Lower_Symbol :: struct {
	value: string,
}

String :: struct {
	value: string,
}

Single_Quoted_String :: struct {
	value: string,
}

Float :: struct {
	value: f64,
}

Integer :: struct {
	value: int,
}

Char :: struct {
	value: byte,
}

Boolean :: struct {
    value: bool
}