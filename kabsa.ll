%{
    #include <stdlib.h>
    #include "kabsa.h"
    #include "kabsa.tab.hh"
    void yyerror(char *);
%}

%option c++

%%

">=" return GE;
"<=" return LE;
"==" return EQ;
"!=" return NE;
"const" return CONSTANT;
"enum" return ENUM;
"while" return WHILE;
"if" return IF;
"else" return ELSE;
"do" return DO;
"for" return FOR;
"switch" return SWITCH;
"function" return FUNCTION;
"true" return TRUE;
"false" return FALSE;
"return" return RETURN;
"case" return CASE;
"break" return BREAK;
"default" return DEFAULT;

[+-]?([0-9]*[.])[0-9]+ {
    yylval.float_value = atof(yytext);
    return FLOAT;
}

[0-9]+ {
    yylval.integer_value = atoi(yytext);
    return INTEGER;
}

[-()<>=+*/:;{}.] {
    return *yytext;
}

[a-zA-Z][a-zA-Z0-9_]* {
    yylval.symbol_table_key = *yytext;
    return IDENTIFIER;
}

[ \t\n]+ ;
. yyerror("Unknown character");

%%

int yywrap(void) {
    return 1;
}