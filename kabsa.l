%{
    #include <stdlib.h>
    #include "y.tab.h"
    void yyerror(char *);
%}

%%

true|false {
    return BOOLEAN;
}

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
"do" return REPEAT;
"for" return FOR;
"switch" return SWITCH;
"function" return FUNCTION;

[a-zA-Z][a-zA-Z0-9_]* {
    return IDENTIFIER;
}

[ \t\n]+ ;
. yyerror("Unknown character");

%%

int yywrap(void) {
    return 1;
}