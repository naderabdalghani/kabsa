%{
	#include "parser.tab.hh"
	#include "scanner.hh"
	#include <cstdarg>

	#define yylex driver.scanner_->yylex
%}


%code requires
{
	#include <iostream>
	#include <iomanip>
	#include "ast.hh"
	#include "driver.hh"
	#include "location.hh"
	#include <string>
	#include <sstream>

	namespace kabsa {
		Node *create_integer_number_node(int value);
		Node *create_double_number_node(double value);
		Node *create_identifier_node(std::string key, identifierEnum identifier_type = VARIABLE_TYPE);
		Node *create_operation_node(int operation_token, int num_of_operands, ...);
		void generate(Node *node);
		void free_node(Node *node);
		static int last_used_label = 0;
		static std::stringstream assembly_ss;
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
%token <int> CONSTANT WHILE IF ENUM DO FOR SWITCH FUNCTION ELSE GE LE EQ NE RETURN CASE BREAK DEFAULT PLUS MINUS MULTIPLY DIVIDE SEMICOLON COLON LEFT_PARENTHESIS RIGHT_PARENTHESIS LEFT_BRACES RIGHT_BRACES ASSIGN GT LT COMMA AND OR NOT CALL PUSH_ARGS
%token <int> INTEGER TRUE FALSE
%token <double> DOUBLE
%token <std::string> IDENTIFIER
%nterm <Node *> main_program program statements statement expression boolean_expression arguments enum_specifier enum_list enumerator assignment parameters function function_call

%nonassoc IFX
%nonassoc ELSE
%left OR
%left AND
%left EQ NE
%left LT LE GT GE
%left PLUS MINUS
%left MULTIPLY DIVIDE
%right NOT
%nonassoc UMINUS


%%

main_program
	:program { driver.write_outfile(assembly_ss); exit(0); }
	;

program
	: %empty {}
	| program function { generate($2); free_node($2);}
	;

function
	: FUNCTION IDENTIFIER LEFT_PARENTHESIS parameters RIGHT_PARENTHESIS statement { $$ = create_operation_node(kabsa::Parser::token::FUNCTION, 3, create_identifier_node($2, FUNCTION_TYPE), $4, $6); }
	;

statement
	: SEMICOLON { $$ = create_operation_node(kabsa::Parser::token::SEMICOLON, 2, NULL, NULL); }
	| expression SEMICOLON { $$ = $1; }
	| RETURN expression SEMICOLON { $$ = create_operation_node(kabsa::Parser::token::RETURN, 1, $2); }
	| assignment SEMICOLON
	| CONSTANT IDENTIFIER ASSIGN expression SEMICOLON { $$ = create_operation_node(kabsa::Parser::token::ASSIGN, 2, create_identifier_node($2, CONSTANT_TYPE), $4); }
	| WHILE LEFT_PARENTHESIS boolean_expression RIGHT_PARENTHESIS statement { $$ = create_operation_node(kabsa::Parser::token::WHILE, 2, $3, $5); }
	| DO statement WHILE LEFT_PARENTHESIS boolean_expression RIGHT_PARENTHESIS SEMICOLON { $$ = create_operation_node(kabsa::Parser::token::DO, 2, $5, $2); }
	| IF LEFT_PARENTHESIS boolean_expression RIGHT_PARENTHESIS statement %prec IFX { $$ = create_operation_node(kabsa::Parser::token::IF, 2, $3, $5); }
	| IF LEFT_PARENTHESIS boolean_expression RIGHT_PARENTHESIS statement ELSE statement { $$ = create_operation_node(kabsa::Parser::token::IF, 3, $3, $5, $7); }
	| FOR LEFT_PARENTHESIS assignment SEMICOLON boolean_expression SEMICOLON assignment RIGHT_PARENTHESIS statement { $$ = create_operation_node(kabsa::Parser::token::FOR, 4, $3, $5, $7, $9); }
	| SWITCH LEFT_PARENTHESIS expression RIGHT_PARENTHESIS LEFT_BRACES labeled_statement RIGHT_BRACES {}
	| LEFT_BRACES statements RIGHT_BRACES { $$ = $2; }
	;

function_call
	: IDENTIFIER LEFT_PARENTHESIS arguments RIGHT_PARENTHESIS  { $$ = create_operation_node(kabsa::Parser::token::CALL, 2, create_identifier_node($1), $3); }
	;

assignment
	: IDENTIFIER ASSIGN expression { $$ = create_operation_node(kabsa::Parser::token::ASSIGN, 2, create_identifier_node($1), $3); }
	;

statements
	: statement
	| statements statement { $$ = create_operation_node(kabsa::Parser::token::SEMICOLON, 2, $1, $2); }
	;

parameters
	: %empty {}
	| IDENTIFIER { $$ = create_identifier_node($1, FUNCTION_PARAMETER_TYPE); }
	| parameters COMMA IDENTIFIER { $$ = create_operation_node(kabsa::Parser::token::COMMA, 2, $1, create_identifier_node($3, FUNCTION_PARAMETER_TYPE)); }
	;

arguments
	: %empty {}
	| expression
	| arguments COMMA expression { $$ = create_operation_node(kabsa::Parser::token::PUSH_ARGS, 2, $1, $3); }
	;

expression
	: INTEGER { $$ = create_integer_number_node($1); }
	| DOUBLE { $$ = create_double_number_node($1); }
	| boolean_expression
	| function_call
	| IDENTIFIER { $$ = create_identifier_node($1); }
	| MINUS expression %prec UMINUS { $$ = create_operation_node(kabsa::Parser::token::UMINUS, 1, $2); }
	| expression PLUS expression { $$ = create_operation_node(kabsa::Parser::token::PLUS, 2, $1, $3); }
	| expression MINUS expression { $$ = create_operation_node(kabsa::Parser::token::MINUS, 2, $1, $3); }
	| expression MULTIPLY expression { $$ = create_operation_node(kabsa::Parser::token::MULTIPLY, 2, $1, $3); }
	| expression DIVIDE expression { $$ = create_operation_node(kabsa::Parser::token::DIVIDE, 2, $1, $3); }
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
	| expression LT expression { $$ = create_operation_node(kabsa::Parser::token::LT, 2, $1, $3); }
	| expression GT expression { $$ = create_operation_node(kabsa::Parser::token::GT, 2, $1, $3); }
	| expression GE expression { $$ = create_operation_node(kabsa::Parser::token::GE, 2, $1, $3); }
	| expression LE expression { $$ = create_operation_node(kabsa::Parser::token::LE, 2, $1, $3); }
	| expression NE expression { $$ = create_operation_node(kabsa::Parser::token::NE, 2, $1, $3); }
	| expression EQ expression { $$ = create_operation_node(kabsa::Parser::token::EQ, 2, $1, $3); }
	| expression AND expression { $$ = create_operation_node(kabsa::Parser::token::AND, 2, $1, $3); }
	| expression OR expression { $$ = create_operation_node(kabsa::Parser::token::OR, 2, $1, $3); }
	| NOT expression { $$ = create_operation_node(kabsa::Parser::token::NOT, 1, $2); }
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
            node->addOperandNode(va_arg(arguments_list, Node *));
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
					assembly_ss<< "\tPUSH\t" << double_number_node->getValue() << std::endl;
				}
				else {
					assembly_ss << "\tPUSH\t" << integer_number_node->getValue() << std::endl;
				}
			} break;
            case IDENTIFIER_TYPE: {
				IdentifierNode *identifier_node = dynamic_cast<IdentifierNode *>(node);
				switch(identifier_node->getIdentifierType()) {
					case FUNCTION_PARAMETER_TYPE: {
						assembly_ss << "\tPOP\t" << identifier_node->getKey() << std::endl;
					} break;
					default:
						assembly_ss << "\tPUSH\t" << identifier_node->getKey() << std::endl;
				}
			} break;
            case OPERATION_TYPE: {
				OperationNode *operation_node = dynamic_cast<OperationNode *>(node);
                switch(operation_node->getOperatorToken()) {
                    case kabsa::Parser::token::WHILE: {
						label_1 = last_used_label++;
						assembly_ss << 'L' << std::setfill('0') << std::setw(4) << label_1 << ':' << std::endl;
                        generate(operation_node->getOperandNode(0));
						label_2 = last_used_label++;
						assembly_ss << "\tJNZ\tL" << std::setfill('0') << std::setw(4) << label_2 << std::endl;
                        generate(operation_node->getOperandNode(1));
						assembly_ss << "\tJMP\tL" << std::setfill('0') << std::setw(4) << label_1 << std::endl;
						assembly_ss << 'L' << std::setfill('0') << std::setw(4) << label_2 << ':' << std::endl;
					} break;
					case kabsa::Parser::token::DO: {
						label_1 = last_used_label++;
						assembly_ss << 'L' << std::setfill('0') << std::setw(4) << label_1 << ':' << std::endl;
                        generate(operation_node->getOperandNode(1));
                        generate(operation_node->getOperandNode(0));
						assembly_ss << "\tJZ\tL" << std::setfill('0') << std::setw(4) << label_1 << std::endl;
					} break;
					//FOR LEFT_PARENTHESIS expression SEMICOLON boolean_expression SEMICOLON expression RIGHT_PARENTHESIS statement { $$ = create_operation_node(kabsa::Parser::token::FOR, 4, $3, $5, $7, $9); }
					case kabsa::Parser::token::FOR: {
						generate(operation_node->getOperandNode(0));
						label_1 = last_used_label++;
						assembly_ss << 'L' << std::setfill('0') << std::setw(4) << label_1 << ':' << std::endl;
						generate(operation_node->getOperandNode(1));
                        label_2 = last_used_label++;
						assembly_ss << "\tJNZ\tL" << std::setfill('0') << std::setw(4) << label_2 << std::endl;
                        generate(operation_node->getOperandNode(3));
                        generate(operation_node->getOperandNode(2));
						assembly_ss << "\tJMP\tL" << std::setfill('0') << std::setw(4) << label_1 << std::endl;
						assembly_ss << 'L' << std::setfill('0') << std::setw(4) << label_2 << ':' << std::endl;
					} break;
                    case kabsa::Parser::token::IF: {
                        generate(operation_node->getOperandNode(0));
                        if (operation_node->getNumberOfOperands() > 2) {
							label_1 = last_used_label++;
							assembly_ss << "\tJNZ\tL" << std::setfill('0') << std::setw(4) << label_1 << std::endl;
                            generate(operation_node->getOperandNode(1));
							label_2 = last_used_label++;
							assembly_ss << "\tJMP\tL" << std::setfill('0') << std::setw(4) << label_2 << std::endl;
							assembly_ss << 'L' << std::setfill('0') << std::setw(4) << label_1 << ':' << std::endl;
                            generate(operation_node->getOperandNode(2));
							assembly_ss << 'L' << std::setfill('0') << std::setw(4) << label_2 << ':' << std::endl;
                        } else {
							label_1 = last_used_label++;
							assembly_ss << "\tJNZ\tL" << std::setfill('0') << std::setw(4) << label_1 << std::endl;
                            generate(operation_node->getOperandNode(1));
							assembly_ss << 'L' << std::setfill('0') << std::setw(4) << label_1 << ':' << std::endl;
                        }
					} break;
					case kabsa::Parser::token::FUNCTION: {
						IdentifierNode *function_identifier_node = dynamic_cast<IdentifierNode *>(operation_node->getOperandNode(0));
						assembly_ss << "\tPROC\t" << function_identifier_node->getKey() << std::endl;
						generate(operation_node->getOperandNode(1));
						generate(operation_node->getOperandNode(2));
						assembly_ss << "\tENDP\t" << function_identifier_node->getKey() << std::endl;
					} break;
					case kabsa::Parser::token::RETURN: {
						generate(operation_node->getOperandNode(0));
						assembly_ss << "\tRET" << std::endl;
					} break;
					case kabsa::Parser::token::CALL: {
						IdentifierNode *function_identifier_node = dynamic_cast<IdentifierNode *>(operation_node->getOperandNode(0));
						generate(operation_node->getOperandNode(1));
						assembly_ss << "\tCALL\t" << function_identifier_node->getKey() << std::endl;
					} break;
                    case kabsa::Parser::token::ASSIGN: {
                        generate(operation_node->getOperandNode(1));
						IdentifierNode *identifier_operand = dynamic_cast<IdentifierNode *>(operation_node->getOperandNode(0));
						assembly_ss << "\tPOP\t" << identifier_operand->getKey() << std::endl;
					} break;
					case kabsa::Parser::token::UMINUS: {
						generate(operation_node->getOperandNode(0));
						assembly_ss << "\tNEG" << std::endl;
					} break;
					case kabsa::Parser::token::PUSH_ARGS: {
						generate(operation_node->getOperandNode(1));
                        generate(operation_node->getOperandNode(0));
					} break;
                    default:
                        generate(operation_node->getOperandNode(0));
                        generate(operation_node->getOperandNode(1));
                        switch(operation_node->getOperatorToken()) {
                            case kabsa::Parser::token::PLUS: assembly_ss << "\tADD" << std::endl; break;
                            case kabsa::Parser::token::MINUS: assembly_ss << "\tSUB" << std::endl; break;
                            case kabsa::Parser::token::MULTIPLY: assembly_ss << "\tMUL" << std::endl; break;
                            case kabsa::Parser::token::DIVIDE: assembly_ss << "\tDIV" << std::endl; break;
                            case kabsa::Parser::token::LT: assembly_ss << "\tCMPLT" << std::endl; break;
                            case kabsa::Parser::token::GT: assembly_ss << "\tCMPGT" << std::endl; break;
                            case kabsa::Parser::token::GE: assembly_ss << "\tCMPGE" << std::endl; break;
                            case kabsa::Parser::token::LE: assembly_ss << "\tCMPLE" << std::endl; break;
                            case kabsa::Parser::token::NE: assembly_ss << "\tCMPNE" << std::endl; break;
                            case kabsa::Parser::token::EQ: assembly_ss << "\tCMPEQ" << std::endl; break;
                            case kabsa::Parser::token::AND: assembly_ss << "\tAND" << std::endl; break;
                            case kabsa::Parser::token::OR: assembly_ss << "\tOR" << std::endl; break;
                            case kabsa::Parser::token::NOT: assembly_ss << "\tNOT" << std::endl; break;
                        }
                }
			} break;
        }
    }

    void free_node(Node *node) {
        if (!node) return;
        if (node->getNodeType() == OPERATION_TYPE) {
			OperationNode *operation_node = dynamic_cast<OperationNode *>(node);
            for (int i = 0; i < operation_node->getNumberOfOperands(); i++)
                free_node(operation_node->getOperandNode(i));
        }
        delete node;
    }
}
