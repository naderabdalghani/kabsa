%{
    #include <stdlib.h>
    #include "y.tab.h"
    void yyerror(char *);
%}

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
"print" return PRINT;
"do" return DO;
"for" return FOR;
"switch" return SWITCH;
"function" return FUNCTION;
"true" return TRUE;
"false" return FALSE;

\"(\\.|[^"\\])*\" {
    return STRING;
}

[0-9]+ {
    yylval = atoi(yytext);
    return INTEGER;
}

[+-]?([0-9]*[.])?[0-9]+ {
    yylval = atof(yytext);
    return FLOAT;
}

[-()<>=+*/;{}.] {
    return *yytext;
}

[a-zA-Z][a-zA-Z0-9_]* {
    return IDENTIFIER;
}

[ \t\n]+ ;
. yyerror("Unknown character");

%%

int yywrap(void) {
    return 1;
}