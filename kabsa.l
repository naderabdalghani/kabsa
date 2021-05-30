%{
    #include <stdlib.h>
    #include "kabsa.h"
    #include "kabsa.tab.h"
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
"do" return DO;
"for" return FOR;
"switch" return SWITCH;
"function" return FUNCTION;
"true" return TRUE;
"false" return FALSE;
"return" return RETURN;

[+-]?([0-9]*[.])[0-9]+ {
    yylval.number.float_value = atof(yytext);
    yylval.number.type = FLOAT_TYPE;
    return FLOAT;
}

[0-9]+ {
    yylval.number.integer_value = atoi(yytext);
    yylval.number.type = INTEGER_TYPE;
    return INTEGER;
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