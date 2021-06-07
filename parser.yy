%{
  #include "parser.tab.hh"
  #include "scanner.hh"

  #define yylex driver.scanner_->yylex
%}

%code requires
{
  #include <iostream>
  #include "driver.hh"
  #include "location.hh"
}

%code provides {
  namespace kabsa {
    class Driver;

    inline void
    yyerror (const char* msg) {
      std::cerr << msg << std::endl;
    }
  }
}



%require "3.2"
%language "C++"
%locations
%defines
%debug
%define api.namespace {kabsa}
%define api.parser.class {Parser}
%parse-param {Driver &driver}
%lex-param {Driver &driver}
%define parse.error verbose

%union
{
 /* YYLTYPE */
}

/* Tokens */
%token TOK_EOF 0

/* Entry point of grammar */
%start start

%%

start:
     /* empty */
;



%%

namespace kabsa
{
    void Parser::error(const location&, const std::string& m)
    {
        std::cerr << *driver.location_ << ": " << m << std::endl;
        driver.error_ = (driver.error_ == 127 ? 127 : driver.error_ + 1);
    }
}
