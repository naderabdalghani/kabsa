%{
    #include <stdio.h>
    #include "kabsa.h"
    int yylex(void);
    void yyerror(char *s);
%}

%union
{
    std::string symbol_table_key;
    int integer_value;
    float float_value;
    Node *node;
};

%token CONSTANT WHILE IF ENUM DO FOR SWITCH FUNCTION INTEGER FLOAT TRUE FALSE IDENTIFIER ELSE GE LE EQ NE RETURN CASE BREAK DEFAULT

%type <integer_value> INTEGER TRUE FALSE
%type <float_value> FLOAT
%type <symbol_table_key> IDENTIFIER
%type <node> program statements statement expression boolean_expression identifiers enum_specifier enum_list enumerator

%nonassoc IFX
%nonassoc ELSE
%left GE LE EQ NE '>' '<'
%left '+' '-'
%left '*' '/'

%%

program
    : // Empty program
    | statement program
    ;


statements
    : statement
    | statements statement
    ;

statement
    : ';'
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
    | SWITCH '(' expression ')' '{' labeled_statement '}'
    | statements
    ;

identifiers
    : IDENTIFIER
    | identifiers ',' IDENTIFIER
    ;

expression
    : INTEGER
    | FLOAT
    | boolean_expression
    | IDENTIFIER
    | expression '+' expression {
        if ($1.type == INTEGER_TYPE && $3.type == INTEGER_TYPE) {
            $$.type = INTEGER_TYPE;
            $$.integer_value = $1.integer_value + $3.integer_value;
        }
        else if ($1.type == INTEGER_TYPE && $3.type == FLOAT_TYPE) {
            $$.type = FLOAT_TYPE; 
            $$.float_value = $1.integer_value + $3.float_value;
        }
        else if ($1.type == FLOAT_TYPE && $3.type == INTEGER_TYPE) {
            $$.type = FLOAT_TYPE; 
            $$.float_value = $1.float_value + $3.integer_value;
        }
        else {
            $$.type = FLOAT_TYPE; 
            $$.float_value = $1.float_value + $3.float_value;
        }
    }
    | expression '-' expression {
        if ($1.type == INTEGER_TYPE && $3.type == INTEGER_TYPE) {
            $$.type = INTEGER_TYPE;
            $$.integer_value = $1.integer_value - $3.integer_value;
        }
        else if ($1.type == INTEGER_TYPE && $3.type == FLOAT_TYPE) {
            $$.type = FLOAT_TYPE; 
            $$.float_value = $1.integer_value - $3.float_value;
        }
        else if ($1.type == FLOAT_TYPE && $3.type == INTEGER_TYPE) {
            $$.type = FLOAT_TYPE; 
            $$.float_value = $1.float_value - $3.integer_value;
        }
        else {
            $$.type = FLOAT_TYPE; 
            $$.float_value = $1.float_value - $3.float_value;
        }
    }
    | expression '*' expression {
        if ($1.type == INTEGER_TYPE && $3.type == INTEGER_TYPE) {
            $$.type = INTEGER_TYPE;
            $$.integer_value = $1.integer_value * $3.integer_value;
        }
        else if ($1.type == INTEGER_TYPE && $3.type == FLOAT_TYPE) {
            $$.type = FLOAT_TYPE; 
            $$.float_value = $1.integer_value * $3.float_value;
        }
        else if ($1.type == FLOAT_TYPE && $3.type == INTEGER_TYPE) {
            $$.type = FLOAT_TYPE; 
            $$.float_value = $1.float_value * $3.integer_value;
        }
        else {
            $$.type = FLOAT_TYPE; 
            $$.float_value = $1.float_value * $3.float_value;
        }
    }
    | expression '/' expression {
        if ($1.type == INTEGER_TYPE && $3.type == INTEGER_TYPE) {
            $$.type = INTEGER_TYPE;
            $$.integer_value = $1.integer_value / $3.integer_value;
        }
        else if ($1.type == INTEGER_TYPE && $3.type == FLOAT_TYPE) {
            $$.type = FLOAT_TYPE; 
            $$.float_value = $1.integer_value / $3.float_value;
        }
        else if ($1.type == FLOAT_TYPE && $3.type == INTEGER_TYPE) {
            $$.type = FLOAT_TYPE; 
            $$.float_value = $1.float_value / $3.integer_value;
        }
        else {
            $$.type = FLOAT_TYPE; 
            $$.float_value = $1.float_value / $3.float_value;
        }
    }
    | '(' expression ')' {
        if ($2.type == INTEGER_TYPE) {
            $$.type = INTEGER_TYPE;
            $$.integer_value = $2.integer_value;
        }
        else {
            $$.type = FLOAT_TYPE;
            $$.float_value = $2.float_value;
        }
    }
    ;

labeled_statements
    : labeled_statement
    | labeled_statements labeled_statement
    ;

labeled_statement
	: CASE expression ':' statement
    | BREAK ';'
	| DEFAULT ':' statement
    | labeled_statements
    ;

enum_specifier
	: ENUM '{' enum_list '}'
	| ENUM IDENTIFIER '{' enum_list '}'
	| ENUM IDENTIFIER '{' '}'
	;

enum_list
	: enumerator
	| enum_list ',' enumerator
	;

enumerator
	: IDENTIFIER
	| IDENTIFIER '=' expression
	;

boolean_expression
    : TRUE {
        $$.type = INTEGER_TYPE;
        $$.integer_value = 1;
    }
    | FALSE {
        $$.type = INTEGER_TYPE;
        $$.integer_value = 0;
    }
    | expression '<' expression {
        $$.type = INTEGER_TYPE;
        if ($1.type == INTEGER_TYPE && $3.type == INTEGER_TYPE) {
            $$.integer_value = $1.integer_value < $3.integer_value;
        }
        else if ($1.type == INTEGER_TYPE && $3.type == FLOAT_TYPE) {
            $$.integer_value = $1.integer_value < $3.float_value;
        }
        else if ($1.type == FLOAT_TYPE && $3.type == INTEGER_TYPE) {
            $$.integer_value = $1.float_value < $3.integer_value;
        }
        else {
            $$.integer_value = $1.float_value < $3.float_value;
        }
    }
    | expression '>' expression {
        $$.type = INTEGER_TYPE;
        if ($1.type == INTEGER_TYPE && $3.type == INTEGER_TYPE) {
            $$.integer_value = $1.integer_value > $3.integer_value;
        }
        else if ($1.type == INTEGER_TYPE && $3.type == FLOAT_TYPE) {
            $$.integer_value = $1.integer_value > $3.float_value;
        }
        else if ($1.type == FLOAT_TYPE && $3.type == INTEGER_TYPE) {
            $$.integer_value = $1.float_value > $3.integer_value;
        }
        else {
            $$.integer_value = $1.float_value > $3.float_value;
        }
    }
    | expression GE expression {
        $$.type = INTEGER_TYPE;
        if ($1.type == INTEGER_TYPE && $3.type == INTEGER_TYPE) {
            $$.integer_value = $1.integer_value >= $3.integer_value;
        }
        else if ($1.type == INTEGER_TYPE && $3.type == FLOAT_TYPE) {
            $$.integer_value = $1.integer_value >= $3.float_value;
        }
        else if ($1.type == FLOAT_TYPE && $3.type == INTEGER_TYPE) {
            $$.integer_value = $1.float_value >= $3.integer_value;
        }
        else {
            $$.integer_value = $1.float_value >= $3.float_value;
        }
    }
    | expression LE expression {
        $$.type = INTEGER_TYPE;
        if ($1.type == INTEGER_TYPE && $3.type == INTEGER_TYPE) {
            $$.integer_value = $1.integer_value <= $3.integer_value;
        }
        else if ($1.type == INTEGER_TYPE && $3.type == FLOAT_TYPE) {
            $$.integer_value = $1.integer_value <= $3.float_value;
        }
        else if ($1.type == FLOAT_TYPE && $3.type == INTEGER_TYPE) {
            $$.integer_value = $1.float_value <= $3.integer_value;
        }
        else {
            $$.integer_value = $1.float_value <= $3.float_value;
        }
    }
    | expression NE expression {
        $$.type = INTEGER_TYPE;
        if ($1.type == INTEGER_TYPE && $3.type == INTEGER_TYPE) {
            $$.integer_value = $1.integer_value != $3.integer_value;
        }
        else if ($1.type == INTEGER_TYPE && $3.type == FLOAT_TYPE) {
            $$.integer_value = $1.integer_value != $3.float_value;
        }
        else if ($1.type == FLOAT_TYPE && $3.type == INTEGER_TYPE) {
            $$.integer_value = $1.float_value != $3.integer_value;
        }
        else {
            $$.integer_value = $1.float_value != $3.float_value;
        }
    }
    | expression EQ expression {
        $$.type = INTEGER_TYPE;
        if ($1.type == INTEGER_TYPE && $3.type == INTEGER_TYPE) {
            $$.integer_value = $1.integer_value == $3.integer_value;
        }
        else if ($1.type == INTEGER_TYPE && $3.type == FLOAT_TYPE) {
            $$.integer_value = $1.integer_value == $3.float_value;
        }
        else if ($1.type == FLOAT_TYPE && $3.type == INTEGER_TYPE) {
            $$.integer_value = $1.float_value == $3.integer_value;
        }
        else {
            $$.integer_value = $1.float_value == $3.float_value;
        }
    }

%%

void yyerror(char *s) {
    fprintf(stdout, "%s\n", s);
}

int main(void) {
    yyparse();
    return 0;
}
