%{
	#include "parser.tab.hh"
	#include "scanner.hh"
	#include <cstdarg>

	#define yylex driver.scanner_->yylex
%}


%code requires
{
	#include <iostream>
	#include "ast.hh"
	#include "driver.hh"
	#include "location.hh"
	#include <string>

	namespace kabsa {
		Node *create_integer_number_node(int value);
		Node *create_double_number_node(double value);
		Node *create_identifier_node(std::string key, identifierEnum identifier_type = VARIABLE_TYPE);
		Node *create_operation_node(int operation_token, int num_of_operands, ...);
		void generate(Node *node);
		/* void free_node(Node *node); */
		static int last_used_label = 0;
	}
}


%code provides {
	namespace kabsa {
		class Driver;

		inline void yyerror (const char* msg) {
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
%define api.value.type variant
%parse-param {Driver &driver}
%lex-param {Driver &driver}
%define parse.error verbose


%token TOK_EOF 0
%token <int> CONSTANT WHILE IF ENUM DO FOR SWITCH FUNCTION ELSE GE LE EQ NE RETURN CASE BREAK DEFAULT PLUS MINUS MULTIPLY DIVIDE SEMICOLON COLON LEFT_PARENTHESIS RIGHT_PARENTHESIS LEFT_BRACES RIGHT_BRACES ASSIGN GT LT COMMA
%token <int> INTEGER TRUE FALSE
%token <double> DOUBLE
%token <std::string> IDENTIFIER
%nterm <Node *> program statements statement expression boolean_expression identifiers enum_specifier enum_list enumerator

%nonassoc IFX
%nonassoc ELSE
%nonassoc UMINUS
%left GE LE EQ NE GT LT
%left PLUS MINUS
%left MULTIPLY DIVIDE


%start program

%%

program
	: %empty {}
	| program statement { generate($2); /* free_node($2); */ exit(0); }
	;

statement
	: SEMICOLON { $$ = create_operation_node($1, 2, NULL, NULL); }
	| expression SEMICOLON { $$ = $1; }
	| RETURN expression { $$ = create_operation_node($1, 1, $2); }
	| IDENTIFIER ASSIGN expression SEMICOLON { $$ = create_operation_node($2, 2, create_identifier_node($1), $3); }
	| CONSTANT IDENTIFIER ASSIGN expression SEMICOLON { $$ = create_operation_node($3, 2, create_identifier_node($2, CONSTANT_TYPE), $4); }
	| WHILE LEFT_PARENTHESIS expression RIGHT_PARENTHESIS statement { $$ = create_operation_node($1, 2, $3, $5); }
	| DO statement WHILE LEFT_PARENTHESIS expression RIGHT_PARENTHESIS { $$ = create_operation_node($1, 2, $5, $2); }
	| IF LEFT_PARENTHESIS boolean_expression RIGHT_PARENTHESIS statement %prec IFX { $$ = create_operation_node($1, 2, $3, $5); }
	| IF LEFT_PARENTHESIS boolean_expression RIGHT_PARENTHESIS statement ELSE statement { $$ = create_operation_node($1, 3, $3, $5, $7); }
	| FOR LEFT_PARENTHESIS expression SEMICOLON boolean_expression SEMICOLON expression RIGHT_PARENTHESIS statement { $$ = create_operation_node($1, 3, $3, $5, $7, $9); }
	| FUNCTION IDENTIFIER LEFT_PARENTHESIS identifiers RIGHT_PARENTHESIS statement {}
	| IDENTIFIER LEFT_PARENTHESIS identifiers RIGHT_PARENTHESIS SEMICOLON {}
	| SWITCH LEFT_PARENTHESIS expression RIGHT_PARENTHESIS LEFT_BRACES labeled_statement RIGHT_BRACES {}
	| LEFT_BRACES statements RIGHT_BRACES { $$ = $2; }
	;

statements
	: statement
	| statements statement { $$ = create_operation_node(kabsa::Parser::token::SEMICOLON, 2, $1, $2); }
	;

identifiers
	: %empty {}
	| identifiers COMMA IDENTIFIER
	;

expression
	: INTEGER { $$ = create_integer_number_node($1); }
	| DOUBLE { $$ = create_double_number_node($1); }
	| boolean_expression
	| IDENTIFIER { $$ = create_identifier_node($1); }
	| MINUS expression %prec UMINUS { $$ = create_operation_node(kabsa::Parser::token::UMINUS, 1, $2); }
	| expression PLUS expression { $$ = create_operation_node($2, 2, $1, $3); }
	| expression MINUS expression { $$ = create_operation_node($2, 2, $1, $3); }
	| expression MULTIPLY expression { $$ = create_operation_node($2, 2, $1, $3); }
	| expression DIVIDE expression { $$ = create_operation_node($2, 2, $1, $3); }
	| LEFT_PARENTHESIS expression RIGHT_PARENTHESIS { $$ = $2; }
	;

labeled_statements
	: labeled_statement
	| labeled_statements labeled_statement
	;

labeled_statement
	: CASE expression COLON statement
	| BREAK SEMICOLON
	| DEFAULT COLON statement
	| LEFT_BRACES labeled_statements RIGHT_BRACES
	;

enum_specifier
	: ENUM LEFT_BRACES enum_list RIGHT_BRACES {}
	| ENUM IDENTIFIER LEFT_BRACES enum_list RIGHT_BRACES {}
	| ENUM IDENTIFIER LEFT_BRACES RIGHT_BRACES {}
	;

enum_list
	: enumerator
	| enum_list COMMA enumerator
	;

enumerator
	: IDENTIFIER  {}
	| IDENTIFIER ASSIGN expression  {}
	;

boolean_expression
	: TRUE { $$ = create_integer_number_node(1); }
	| FALSE { $$ = create_integer_number_node(0); }
	| expression LT expression { $$ = create_operation_node($2, 2, $1, $3); }
	| expression GT expression { $$ = create_operation_node($2, 2, $1, $3); }
	| expression GE expression { $$ = create_operation_node($2, 2, $1, $3); }
	| expression LE expression { $$ = create_operation_node($2, 2, $1, $3); }
	| expression NE expression { $$ = create_operation_node($2, 2, $1, $3); }
	| expression EQ expression { $$ = create_operation_node($2, 2, $1, $3); }
	;

%%


namespace kabsa
{
    void Parser::error(const location&, const std::string& m)
    {
        std::cerr << *driver.location_ << ": " << m << std::endl;
        driver.error_ = (driver.error_ == 127 ? 127 : driver.error_ + 1);
    }

    Node *create_integer_number_node(int value) {
        NumberNode<int> *node = new NumberNode<int>(value);
        return node;
    }

    Node *create_double_number_node(double value) {
        NumberNode<double> *node = new NumberNode<double>(value);
		return node;
    }

    Node *create_identifier_node(std::string key, identifierEnum identifier_type) {
		IdentifierNode *node = new IdentifierNode(identifier_type, key);
        return node;
    }

    Node *create_operation_node(int operation_token, int num_of_operands, ...) {
        va_list arguments_list;
        OperationNode *node = new OperationNode(operation_token);

        va_start(arguments_list, num_of_operands);
        for (int i = 0; i < num_of_operands; i++)
            node->getOperands().push_back(va_arg(arguments_list, Node *));
        va_end(arguments_list);

        return node;
    }

    void generate(Node *node) {
        int label_1, label_2;
        if (!node) return;
        switch(node->getNodeType()) {
            case NUMBER_TYPE: {
				NumberNode<int> *integer_number_node = dynamic_cast<NumberNode<int> *>(node);
				NumberNode<double> *double_number_node = dynamic_cast<NumberNode<double> *>(node);
				if (integer_number_node == NULL) {
					printf("\tPUSH\t%d\n", double_number_node->getValue());
				}
				else {
					printf("\tPUSH\t%d\n", integer_number_node->getValue());
				}
			} break;
            case IDENTIFIER_TYPE: {
				IdentifierNode *identifier_node = dynamic_cast<IdentifierNode *>(node);
                printf("\tPUSH\t%s\n", identifier_node->getKey());
			} break;
            case OPERATION_TYPE: {
				OperationNode *operation_node = dynamic_cast<OperationNode *>(node);
				std::vector<Node *> operands = operation_node->getOperands();
                switch(operation_node->getOperatorToken()) {
                    case kabsa::Parser::token::WHILE: {
                        printf("L%03d:\n", label_1 = last_used_label++);
                        generate(operands[0]);
                        printf("\tJZ\tL%03d\n", label_2 = last_used_label++);
                        generate(operands[1]);
                        printf("\tJMP\tL%03d\n", label_1);
                        printf("L%03d:\n", label_2);
					} break;
                    case kabsa::Parser::token::IF: {
                        generate(operands[0]);
                        if (operands.size() > 2) {
                            printf("\tJZ\tL%03d\n", label_1 = last_used_label++);
                            generate(operands[1]);
                            printf("\tJMP\tL%03d\n", label_2 = last_used_label++);
                            printf("L%03d:\n", label_1);
                            generate(operands[2]);
                            printf("L%03d:\n", label_2);
                        } else {
                            printf("\tJZ\tL%03d\n", label_1 = last_used_label++);
                            generate(operands[1]);
                            printf("L%03d:\n", label_1);
                        }
					} break;
                    case kabsa::Parser::token::ASSIGN: {
                        generate(operands[1]);
						IdentifierNode *identifier_operand = dynamic_cast<IdentifierNode *>(operands[0]);
                        printf("\tPOP\t%c\n", identifier_operand->getKey());
					} break;
					case kabsa::Parser::token::UMINUS: {
						generate(operands[0]);
						printf("\tNEG\n");
					} break;
                    default:
                        generate(operands[0]);
                        generate(operands[1]);
                        switch(operation_node->getOperatorToken()) {
                            case kabsa::Parser::token::PLUS: printf("\tADD\n"); break;
                            case kabsa::Parser::token::MINUS: printf("\tSUB\n"); break;
                            case kabsa::Parser::token::MULTIPLY: printf("\tMUL\n"); break;
                            case kabsa::Parser::token::DIVIDE: printf("\tDIV\n"); break;
                            case kabsa::Parser::token::LT: printf("\tCMPLT\n"); break;
                            case kabsa::Parser::token::GT: printf("\tCMPGT\n"); break;
                            case kabsa::Parser::token::GE: printf("\tCMPGE\n"); break;
                            case kabsa::Parser::token::LE: printf("\tCMPLE\n"); break;
                            case kabsa::Parser::token::NE: printf("\tCMPNE\n"); break;
                            case kabsa::Parser::token::EQ: printf("\tCMPEQ\n"); break;
                        }
                }
			} break;
        }
    }

    /* void free_node(Node node) {
        if (!node) return;
        if (node->type == OPERATION_TYPE) {
            for (int i = 0; i < node->operation.num_of_operands; i++)
                free_node(node->operation.operands[i]);
        }
        delete node;
    } */
}
