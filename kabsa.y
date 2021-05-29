%{
    #include <stdio.h>

    int yylex(void);
    void yyerror(char *s);

%}

%union {
    int integer_value;
    float float_value;
};

%token CONSTANT WHILE IF ENUM DO FOR SWITCH FUNCTION INTEGER FLOAT TRUE FALSE IDENTIFIER ELSE GE LE EQ NE RETURN

%type <integer_value> INTEGER
%type <integer_value> TRUE
%type <integer_value> FALSE
%type <float_value> FLOAT

%nonassoc IFX
%nonassoc ELSE
%left GE LE EQ NE '>' '<'
%left '+' '-'
%left '*' '/'

%%

program
      : /* Empty program */
      │ statement program
      ;


statements
    : statement
    | statements statement
    ;

statement
    : ';' { $$ = NULL; }
    | expression ';'
    | RETURN expression { printf("Return"); }
    | IDENTIFIER '=' expression ';' { printf("Assignment"); }
    | CONSTANT IDENTIFIER '=' expression ';' { printf("Constant Assignment") }
    | WHILE '(' expression ')' '{' statement '}' { printf("While Loop"); }
    | DO '{' statement '}' WHILE '(' expression ')' { printf("Do-While Loop"); }
    | IF '(' boolean_expression ')' '{' statement '}' %prec IFX { printf("If Statement"); }
    | IF '(' boolean_expression ')' '{' statement '}' ELSE '{' statement '}' { printf("If-Else Statement"); }
    | FOR '(' expression ';' boolean_expression ';' expression ')' { printf("For Loop"); }
    | FUNCTION IDENTIFIER '(' identifiers ')' '{' statement '}' { printf("Function Declaration") }
    | IDENTIFIER '(' identifiers ')' ';' { printf("Function Call") }
    | statements
    ;

identifiers
    : IDENTIFIER
    | identifiers ',' IDENTIFIER { ; }
    ;

expression
    : INTEGER
    | FLOAT
    | boolean_expression
    | IDENTIFIER
    | expression '+' expression { $$ = $1 + $3; }
    | expression '-' expression { $$ = $1 - $3; }
    | expression '*' expression { $$ = $1 * $3; }
    | expression '/' expression { $$ = $1 / $3; }
    | '(' expression ')' { $$ = $2; }
    ;

enum_specifier
	: ENUM '{' enumerator_list '}'
	| ENUM IDENTIFIER '{' enumerator_list '}'
	| ENUM IDENTIFIER '{' '}'
	;

enumerator_list
	: enumerator
	| enumerator_list ',' enumerator
	;

enumerator
	: IDENTIFIER
	| IDENTIFIER '=' expression
	;

boolean_expression
    : TRUE { $$ = 1; }
    | FALSE { $$ = 0; }
    | expression '<' expression { $$ = $1 < $3; }
    | expression '>' expression { $$ = $1 > $3; }
    | expression GE expression { $$ = $1 >= $3; }
    | expression LE expression { $$ = $1 <= $3; }
    | expression NE expression { $$ = $1 != $3; }
    | expression EQ expression { $$ = $1 == $3; }

%%

void yyerror(char *s) {
    fprintf(stdout, "%s\n", s);
}

int main(void) {
    yyparse();
    return 0;
}
