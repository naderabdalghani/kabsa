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

{eol} LINE(yyleng / 2);

">=" {
	STEP();
	return kabsa::Parser::token::GE;
}

"<=" {
	STEP();
	return kabsa::Parser::token::LE;
}

"==" {
	STEP();
	return kabsa::Parser::token::EQ;
}

"!=" {
	STEP();
	return kabsa::Parser::token::NE;
}

"+"  {
	STEP();
	return kabsa::Parser::token::PLUS;
}

"-"  {
	STEP();
	return kabsa::Parser::token::MINUS;
}

"*"  {
	STEP();
	return kabsa::Parser::token::MULTIPLY;
}

"/"  {
	STEP();
	return kabsa::Parser::token::DIVIDE;
}

";"  {
	STEP();
	return kabsa::Parser::token::SEMICOLON;
}

","  {
	STEP();
	return kabsa::Parser::token::COMMA;
}

":"  {
	STEP();
	return kabsa::Parser::token::COLON;
}

"("  {
	STEP();
	return kabsa::Parser::token::LEFT_PARENTHESIS;
}

")"  {
	STEP();
	return kabsa::Parser::token::RIGHT_PARENTHESIS;
}

"{"  {
	STEP();
	return kabsa::Parser::token::LEFT_BRACES;
}

"}"  {
	STEP();
	return kabsa::Parser::token::RIGHT_BRACES;
}

"="  {
	STEP();
	return kabsa::Parser::token::ASSIGN;
}

">" {
	STEP();
	return kabsa::Parser::token::GT;
}

"<" {
	STEP();
	return kabsa::Parser::token::LT;
}

"&" {
	STEP();
	return kabsa::Parser::token::AND;
}

"|" {
	STEP();
	return kabsa::Parser::token::OR;
}

"!" {
	STEP();
	return kabsa::Parser::token::NOT;
}

"const" {
	STEP();
	return kabsa::Parser::token::CONSTANT;
}

"enum" {
	STEP();
	return kabsa::Parser::token::ENUM;
}

"while" {
	STEP();
	return kabsa::Parser::token::WHILE;
}

"if" {
	STEP();
	return kabsa::Parser::token::IF;
}

"else" {
	STEP();
	return kabsa::Parser::token::ELSE;
}

"do" {
	STEP();
	return kabsa::Parser::token::DO;
}

"for" {
	STEP();
	return kabsa::Parser::token::FOR;
}

"switch" {
	STEP();
	return kabsa::Parser::token::SWITCH;
}

"function" {
	STEP();
	return kabsa::Parser::token::FUNCTION;
}

"true" {
	STEP();
	return kabsa::Parser::token::TRUE;
}

"false" {
	STEP();
	return kabsa::Parser::token::FALSE;
}

"return" {
	STEP();
	return kabsa::Parser::token::RETURN;
}

"case" {
	STEP();
	return kabsa::Parser::token::CASE;
}

"break" {
	STEP();
	return kabsa::Parser::token::BREAK;
}

"default" {
	STEP();
	return kabsa::Parser::token::DEFAULT;
}

[+-]?([0-9]*[.])[0-9]+ {
	STEP();
    yylval->emplace<double>(atof(yytext));
    return kabsa::Parser::token::DOUBLE;
}

[0-9]+ {
	STEP();
    yylval->emplace<int>(atoi(yytext));
    return kabsa::Parser::token::INTEGER;
}

[a-zA-Z][a-zA-Z0-9_]* {
	STEP();
    yylval->emplace<std::string>(yytext);
    return kabsa::Parser::token::IDENTIFIER;
}

. {
	std::cerr << *driver.location_ << " Unexpected token : " << *yytext << std::endl;
	exit(0);
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
