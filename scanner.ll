%{
	#include "parser.tab.hh"
	#include "scanner.hh"
	#include "driver.hh"
	#include <cstdlib>

	#define STEP() driver.location_->step();
	#define COL(Col) driver.location_->columns(Col);
	#define LINE(Line) driver.location_->lines(Line);
	#define YY_USER_ACTION COL(yyleng);

	typedef kabsa::Parser::token token;
	typedef kabsa::Parser::token_type token_type;

	#define yyterminate() return token::TOK_EOF
%}

%option c++
%option noyywrap
%option never-interactive
%option yylineno
%option nounput
%option batch
%option prefix="kabsa"

blank   [ \t]+
eol     [\n\r]+

%%

%{
  STEP();
%}


{blank} STEP();

{eol} LINE(yyleng);

">=" return kabsa::Parser::token::GE;
"<=" return kabsa::Parser::token::LE;
"==" return kabsa::Parser::token::EQ;
"!=" return kabsa::Parser::token::NE;
"+"  return kabsa::Parser::token::PLUS;
"-"  return kabsa::Parser::token::MINUS;
"*"  return kabsa::Parser::token::MULTIPLY;
"/"  return kabsa::Parser::token::DIVIDE;
";"  return kabsa::Parser::token::SEMICOLON;
","  return kabsa::Parser::token::COMMA;
":"  return kabsa::Parser::token::COLON;
"("  return kabsa::Parser::token::LEFT_PARENTHESIS;
")"  return kabsa::Parser::token::RIGHT_PARENTHESIS;
"{"  return kabsa::Parser::token::LEFT_BRACES;
"}"  return kabsa::Parser::token::RIGHT_BRACES;
"="  return kabsa::Parser::token::ASSIGN;
">" return kabsa::Parser::token::GT;
"<" return kabsa::Parser::token::LT;
"const" return kabsa::Parser::token::CONSTANT;
"enum" return kabsa::Parser::token::ENUM;
"while" return kabsa::Parser::token::WHILE;
"if" return kabsa::Parser::token::IF;
"else" return kabsa::Parser::token::ELSE;
"do" return kabsa::Parser::token::DO;
"for" return kabsa::Parser::token::FOR;
"switch" return kabsa::Parser::token::SWITCH;
"function" return kabsa::Parser::token::FUNCTION;
"true" return kabsa::Parser::token::TRUE;
"false" return kabsa::Parser::token::FALSE;
"return" return kabsa::Parser::token::RETURN;
"case" return kabsa::Parser::token::CASE;
"break" return kabsa::Parser::token::BREAK;
"default" return kabsa::Parser::token::DEFAULT;

[+-]?([0-9]*[.])[0-9]+ {
    yylval->emplace<double>(atof(yytext));
    return kabsa::Parser::token::DOUBLE;
}

[0-9]+ {
    yylval->emplace<int>(atoi(yytext));
    return kabsa::Parser::token::INTEGER;
}

[a-zA-Z][a-zA-Z0-9_]* {
    yylval->emplace<std::string>(yytext);
    return kabsa::Parser::token::IDENTIFIER;
}

. {
	std::cerr << *driver.location_ << " Unexpected token : " << *yytext << std::endl;
	driver.error_ = (driver.error_ == 127 ? 127 : driver.error_ + 1);
	STEP ();
}

%%

namespace kabsa
{
    Scanner::Scanner() : kabsaFlexLexer() {}

    Scanner::~Scanner() {}

    void Scanner::set_debug(bool b) { yy_flex_debug = b; }
}

#ifdef yylex
# undef yylex
#endif

int kabsaFlexLexer::yylex()
{
	std::cerr << "call kabsaFlexLexer::yylex()!" << std::endl;
	return 0;
}
