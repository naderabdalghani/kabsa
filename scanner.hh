
#ifndef SCANPIT_HH_
# define SCANPIT_HH_

# include "parser.tab.hh"


# ifndef YY_DECL
#  define YY_DECL kabsa::Parser::token_type kabsa::Scanner::yylex(kabsa::Parser::semantic_type* yylval, kabsa::Parser::location_type*, kabsa::Driver& driver)
# endif


# ifndef __FLEX_LEXER_H
#  define yyFlexLexer kabsaFlexLexer
#  include <FlexLexer.h>
#  undef yyFlexLexer
# endif


namespace kabsa {
    class Scanner : public kabsaFlexLexer {
        public:
            Scanner();
            virtual ~Scanner();
            virtual Parser::token_type yylex(Parser::semantic_type* yylval, Parser::location_type* l, Driver& driver);
            void set_debug(bool b);
    };
}

#endif // SCANPIT_HH_
