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
	#include <algorithm>
	#include <unordered_map>

	namespace kabsa {
		Node *create_integer_number_node(int value);
		Node *create_double_number_node(double value);
		Node *create_identifier_node(const location& l, std::string key, identifierEnum identifier_type = VARIABLE_TYPE, bool assignment = true);
		std::string identifierTypeAsString(identifierEnum identifier_type);
		Node *get_identifier_node(const location& l, std::string key, std::vector<identifierEnum> valid_identifier_types);
		Node *create_operation_node(int operation_token, int num_of_operands, ...);
		void generate(Node *node);
		bool isValidType(identifierEnum identifier_type, std::vector<identifierEnum> valid_identifier_types);
		static int last_used_label = 0;
		static std::stringstream assembly_ss;
	    static std::unordered_map<std::string, IdentifierNode*> symbol_table;
	}
}


%code provides {
	namespace kabsa {
		class Driver;

		inline void yyerror (const location& l, const char* msg) {
        	std::cerr << l << ": " << msg << std::endl; exit(1);
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
%nterm <Node *> main_program program statements statement expression boolean_expression arguments enum_specifier enum_list enumerator variable_assignment constant_assignment parameters function_declaration function_call constant_expression labeled_statement labeled_statements variable_declaration constant_declaration

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
	| program function_declaration { generate($2); }
	;

function_declaration
	: FUNCTION IDENTIFIER LEFT_PARENTHESIS parameters RIGHT_PARENTHESIS statement { $$ = create_operation_node(kabsa::Parser::token::FUNCTION, 3, create_identifier_node(*driver.location_, $2, FUNCTION_TYPE), $4, $6); }
	;

statement
	: SEMICOLON { $$ = create_operation_node(kabsa::Parser::token::SEMICOLON, 2, NULL, NULL); }
	| RETURN expression SEMICOLON { $$ = create_operation_node(kabsa::Parser::token::RETURN, 1, $2); }
	| RETURN SEMICOLON { $$ = create_operation_node(kabsa::Parser::token::RETURN, 0); }
	| variable_assignment SEMICOLON
	| constant_assignment SEMICOLON
	| variable_declaration
	| constant_declaration
	| WHILE LEFT_PARENTHESIS boolean_expression RIGHT_PARENTHESIS statement { $$ = create_operation_node(kabsa::Parser::token::WHILE, 2, $3, $5); }
	| DO statement WHILE LEFT_PARENTHESIS boolean_expression RIGHT_PARENTHESIS SEMICOLON { $$ = create_operation_node(kabsa::Parser::token::DO, 2, $5, $2); }
	| IF LEFT_PARENTHESIS boolean_expression RIGHT_PARENTHESIS statement %prec IFX { $$ = create_operation_node(kabsa::Parser::token::IF, 2, $3, $5); }
	| IF LEFT_PARENTHESIS boolean_expression RIGHT_PARENTHESIS statement ELSE statement { $$ = create_operation_node(kabsa::Parser::token::IF, 3, $3, $5, $7); }
	| FOR LEFT_PARENTHESIS variable_assignment SEMICOLON boolean_expression SEMICOLON variable_assignment RIGHT_PARENTHESIS statement { $$ = create_operation_node(kabsa::Parser::token::FOR, 4, $3, $5, $7, $9); }
	| SWITCH LEFT_PARENTHESIS expression RIGHT_PARENTHESIS LEFT_BRACES labeled_statements RIGHT_BRACES { $$ = create_operation_node(kabsa::Parser::token::SWITCH, 2, $3, $6); }
	| LEFT_BRACES statements RIGHT_BRACES { $$ = $2; }
	;

function_call
	: IDENTIFIER LEFT_PARENTHESIS arguments RIGHT_PARENTHESIS  { $$ = create_operation_node(kabsa::Parser::token::CALL, 2, get_identifier_node(*driver.location_, $1, std::vector<identifierEnum> {FUNCTION_TYPE}), $3); }
	;

variable_assignment
	: IDENTIFIER ASSIGN expression { $$ = create_operation_node(kabsa::Parser::token::ASSIGN, 2, create_identifier_node(*driver.location_, $1, VARIABLE_TYPE), $3); }
	;

constant_assignment
	: CONSTANT IDENTIFIER ASSIGN expression { $$ = create_operation_node(kabsa::Parser::token::ASSIGN, 2, create_identifier_node(*driver.location_, $2, CONSTANT_TYPE), $4); }
	;

variable_declaration
	: IDENTIFIER SEMICOLON { $$ = create_identifier_node(*driver.location_, $1, VARIABLE_TYPE, false); }
	;

constant_declaration
	: CONSTANT IDENTIFIER SEMICOLON { $$ = create_identifier_node(*driver.location_, $2, CONSTANT_TYPE, false); }
	;

statements
	: statement
	| statements statement { $$ = create_operation_node(kabsa::Parser::token::SEMICOLON, 2, $1, $2); }
	;

parameters
	: %empty {}
	| IDENTIFIER { $$ = create_identifier_node(*driver.location_, $1, FUNCTION_PARAMETER_TYPE); }
	| parameters COMMA IDENTIFIER { $$ = create_operation_node(kabsa::Parser::token::COMMA, 2, $1, create_identifier_node(*driver.location_, $3, FUNCTION_PARAMETER_TYPE)); }
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
	| IDENTIFIER { $$ = get_identifier_node(*driver.location_, $1, std::vector<identifierEnum> {CONSTANT_TYPE, VARIABLE_TYPE, FUNCTION_PARAMETER_TYPE}); }
	| MINUS expression %prec UMINUS { $$ = create_operation_node(kabsa::Parser::token::UMINUS, 1, $2); }
	| expression PLUS expression { $$ = create_operation_node(kabsa::Parser::token::PLUS, 2, $1, $3); }
	| expression MINUS expression { $$ = create_operation_node(kabsa::Parser::token::MINUS, 2, $1, $3); }
	| expression MULTIPLY expression { $$ = create_operation_node(kabsa::Parser::token::MULTIPLY, 2, $1, $3); }
	| expression DIVIDE expression { $$ = create_operation_node(kabsa::Parser::token::DIVIDE, 2, $1, $3); }
	| LEFT_PARENTHESIS expression RIGHT_PARENTHESIS { $$ = $2; }
	;

labeled_statements
	: labeled_statement
	| labeled_statements labeled_statement { $$ = create_operation_node(kabsa::Parser::token::SEMICOLON, 2, $1, $2); }
	;

labeled_statement
	: CASE constant_expression COLON statement { $$ = create_operation_node(kabsa::Parser::token::CASE, 2, $2, $4); }
	| DEFAULT COLON statement { $$ = create_operation_node(kabsa::Parser::token::DEFAULT, 1, $3); }
	| DEFAULT COLON { $$ = create_operation_node(kabsa::Parser::token::DEFAULT, 0); }
	| BREAK SEMICOLON { $$ = create_operation_node(kabsa::Parser::token::BREAK, 0); }
	;

constant_expression
	: INTEGER { $$ = create_integer_number_node($1); }
	| IDENTIFIER { $$ = get_identifier_node(*driver.location_, $1, std::vector<identifierEnum> {CONSTANT_TYPE}); }
	;

/* enum_specifier
	: ENUM LEFT_BRACES enum_list RIGHT_BRACES {}
	| ENUM IDENTIFIER LEFT_BRACES enum_list RIGHT_BRACES {}
	| ENUM IDENTIFIER LEFT_BRACES RIGHT_BRACES {}
	;

enum_list
	: IDENTIFIER
	| enum_list COMMA IDENTIFIER
	; */

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
    void Parser::error(const location& l, const std::string& m) {
        std::cerr << *driver.location_ << ": " << m << std::endl;
    }

    Node *create_integer_number_node(int value) {
        NumberNode<int> *node = new NumberNode<int>(value);
        return node;
    }

    Node *create_double_number_node(double value) {
        NumberNode<double> *node = new NumberNode<double>(value);
		return node;
    }

    Node *create_identifier_node(const location& l, std::string key, identifierEnum identifier_type, bool assignment) {
		auto iterator = symbol_table.find(key);
		if (identifier_type == VARIABLE_TYPE && iterator != symbol_table.end()) {
			if (iterator->second->getIdentifierType() == CONSTANT_TYPE) {
				yyerror(l, "Cannot reassign value to constant variable");
			}
		}
		IdentifierNode *node = new IdentifierNode(key, identifier_type, assignment);
		symbol_table[key] = node;
        return node;
    }

	bool isValidType(identifierEnum identifier_type, std::vector<identifierEnum> valid_identifier_types) {
		auto iterator = std::find(valid_identifier_types.begin(), valid_identifier_types.end(), identifier_type);
		if (iterator != valid_identifier_types.end()) {
			return true;
		}
		return false;
	}

	std::string identifierTypeAsString(identifierEnum identifier_type) {
		switch(identifier_type) {
			case CONSTANT_TYPE:
				return "constant variable";
			case FUNCTION_TYPE:
				return "function";
			default:
				return "variable";
		}
	}

	Node *get_identifier_node(const location& l, std::string key, std::vector<identifierEnum> valid_identifier_types) {
		auto iterator = symbol_table.find(key);
		if (iterator != symbol_table.end()) {
			IdentifierNode *node = iterator->second;
			if (not isValidType(node->getIdentifierType(), valid_identifier_types)) {
				std::string valid_types_as_strings;
				std::string separator = " or as a ";
				std::string last_variable_type_string = "";
				for(identifierEnum valid_type : valid_identifier_types) {
					std::string type_string = identifierTypeAsString(valid_type);
					if (last_variable_type_string != type_string) {
						valid_types_as_strings = valid_types_as_strings + type_string + separator;
					}
					last_variable_type_string = type_string;
				}
				valid_types_as_strings = valid_types_as_strings.substr(0, valid_types_as_strings.length() - separator.length());
				std::cerr << l << ": " << "Cannot use " << identifierTypeAsString(node->getIdentifierType()) << " as a " << valid_types_as_strings << std::endl; exit(1);
			}
			if (!node->isInitialized()){
				std::cerr << l << ": " << "Uninitialized " + identifierTypeAsString(node->getIdentifierType()) + " used" << std::endl; exit(1);
			}
			return node;
		}
		else {
			if (isValidType(FUNCTION_TYPE, valid_identifier_types)) {
				std::cerr << l << ": " << "Undeclared " << identifierTypeAsString(FUNCTION_TYPE) << " used" << std::endl; exit(1);
			}
			else if (isValidType(CONSTANT_TYPE, valid_identifier_types) && !isValidType(VARIABLE_TYPE, valid_identifier_types)) {
				std::cerr << l << ": " << "Undeclared " << identifierTypeAsString(CONSTANT_TYPE) << " used" << std::endl; exit(1);
			}
			else {
				std::cerr << l << ": " << "Undeclared " << identifierTypeAsString(VARIABLE_TYPE) << " used" << std::endl; exit(1);
			}
		}
		return NULL;
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
						if (operation_node->getNumberOfOperands() > 0) {
							generate(operation_node->getOperandNode(0));
						}
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
					case kabsa::Parser::token::SWITCH: {
						std::vector<OperationNode *> labeled_statements;
						std::vector<int> switch_labels;
						OperationNode *labeled_statement = dynamic_cast<OperationNode *>(operation_node->getOperandNode(1));
						while (labeled_statement->getOperatorToken() == kabsa::Parser::token::SEMICOLON) {
							labeled_statements.push_back(dynamic_cast<OperationNode *>(labeled_statement->getOperandNode(1)));
							labeled_statement = dynamic_cast<OperationNode *>(labeled_statement->getOperandNode(0));
						}
						labeled_statements.push_back(labeled_statement);
						std::reverse(labeled_statements.begin(), labeled_statements.end());
						for (int i = 0; i < labeled_statements.size(); i++) {
							switch(labeled_statements[i]->getOperatorToken()) {
								case kabsa::Parser::token::CASE: {
									generate(operation_node->getOperandNode(0));
									generate(labeled_statements[i]->getOperandNode(0));
									assembly_ss << "\tCMPEQ" << std::endl;
									label_1 = last_used_label++;
									assembly_ss << "\tJZ\tL" << std::setfill('0') << std::setw(4) << label_1 << std::endl;
									switch_labels.push_back(label_1);
								} break;
							}
						}
						label_1 = last_used_label++;
						assembly_ss << "\tJMP\tL" << std::setfill('0') << std::setw(4) << label_1 << std::endl;
						switch_labels.push_back(label_1);
						int break_label = last_used_label++;
						int label_index = 0;
						for (int i = 0; i < labeled_statements.size(); i++) {
							switch(labeled_statements[i]->getOperatorToken()) {
								case kabsa::Parser::token::CASE: {
									assembly_ss << 'L' << std::setfill('0') << std::setw(4) << switch_labels[label_index++] << ':' << std::endl;
									generate(labeled_statements[i]->getOperandNode(1));
								} break;
								case kabsa::Parser::token::DEFAULT: {
									assembly_ss << 'L' << std::setfill('0') << std::setw(4) << switch_labels[label_index++] << ':' << std::endl;
									if (labeled_statements[i]->getNumberOfOperands() > 0) {
										generate(labeled_statements[i]->getOperandNode(0));
									}
								} break;
								case kabsa::Parser::token::BREAK: {
									assembly_ss << "\tJMP\tL" << std::setfill('0') << std::setw(4) << break_label << std::endl;
								} break;
							}
						}
						assembly_ss << 'L' << std::setfill('0') << std::setw(4) << break_label << ':' << std::endl;
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
}
