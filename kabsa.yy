%language "c++"

%{
    #include <stdio.h>
    #include <stdlib.h>
    #include <stdarg.h>
    #include <string>
    #include <unordered_map>
    #include <iostream>
    #include "kabsa.h"

    /* functions prototypes */
    Node *create_integer_number_node(int value);
    Node *create_float_number_node(float value);
    Node *create_identifier_node(string key);
    Node *create_operation_node(int operation_token, int num_of_operands, ...);
    void generate(Node *node);
    void free_node(Node *node);
    int yylex(void);
    void yyerror(char *s);

    unordered_map<string, Node> symbol_table;
    static int last_used_label = 0;
%}

%union
{
    std::string symbol_table_key;
    int integer_value;
    float float_value;
    Node *node;
};

%token CONSTANT WHILE IF ENUM DO FOR SWITCH FUNCTION INTEGER FLOAT TRUE FALSE IDENTIFIER ELSE GE LE EQ NE RETURN CASE BREAK DEFAULT

%type <integer_value> INTEGER TRUE FALSE
%type <float_value> FLOAT
%type <symbol_table_key> IDENTIFIER
%type <node> program statements statement expression boolean_expression identifiers enum_specifier enum_list enumerator

%nonassoc IFX
%nonassoc ELSE
%left GE LE EQ NE '>' '<'
%left '+' '-'
%left '*' '/'

%%

program
    : // Empty program
    | program statement { generate($2); free_node($2); exit(0); }
    ;


statements
    : statement
    | statements statement { $$ = create_operation_node(';', 2, $1, $2); }
    ;

statement
    : ';' { $$ = create_operation_node(';', 2, NULL, NULL); }
    | expression ';' { $$ = $1; }
    | RETURN expression { $$ = create_operation_node(RETURN, 1, $2); }
    | IDENTIFIER '=' expression ';' { $$ = create_operation_node('=', 2, create_identifier_node($1), $3); }
    | CONSTANT IDENTIFIER '=' expression ';' { $$ = create_operation_node('=', 2, create_identifier_node($2, CONSTANT_TYPE), $4); }
    | WHILE '(' expression ')' '{' statement '}' { $$ = create_operation_node(WHILE, 2, $3, $6); }
    | DO '{' statement '}' WHILE '(' expression ')' { $$ = create_operation_node(DO, 2, $3, $7); }
    | IF '(' boolean_expression ')' '{' statement '}' %prec IFX { $$ = create_operation_node(IF, 2, $3, $6); }
    | IF '(' boolean_expression ')' '{' statement '}' ELSE '{' statement '}' { $$ = create_operation_node(IF, 3, $3, $6, $10); }
    | FOR '(' expression ';' boolean_expression ';' expression ')' '{' statement '}' { $$ = create_operation_node(FOR, 3, $3, $5, $7, $10); }
    | FUNCTION IDENTIFIER '(' identifiers ')' '{' statement '}'
    | IDENTIFIER '(' identifiers ')' ';'
    | SWITCH '(' expression ')' '{' labeled_statement '}'
    | statements
    ;

identifiers
    : IDENTIFIER
    | identifiers ',' IDENTIFIER
    ;

expression
    : INTEGER { $$ = create_integer_number_node($1); }
    | FLOAT { $$ = create_float_number_node($1); }
    | boolean_expression { $$ = $1; }
    | IDENTIFIER { $$ = create_identifier_node($1); }
    | expression '+' expression { $$ = create_operation_node('+', 2, $1, $3); }
    | expression '-' expression { $$ = create_operation_node('-', 2, $1, $3); }
    | expression '*' expression { $$ = create_operation_node('*', 2, $1, $3); }
    | expression '/' expression { $$ = create_operation_node('/', 2, $1, $3); }
    | '(' expression ')' { $$ = $2; }
    ;

labeled_statements
    : labeled_statement
    | labeled_statements labeled_statement
    ;

labeled_statement
	: CASE expression ':' statement
    | BREAK ';'
	| DEFAULT ':' statement
    | labeled_statements
    ;

enum_specifier
	: ENUM '{' enum_list '}'
	| ENUM IDENTIFIER '{' enum_list '}'
	| ENUM IDENTIFIER '{' '}'
	;

enum_list
	: enumerator
	| enum_list ',' enumerator
	;

enumerator
	: IDENTIFIER
	| IDENTIFIER '=' expression
	;

boolean_expression
    : TRUE { $$ = create_integer_number_node(1); }
    | FALSE { $$ = create_integer_number_node(0); }
    | expression '<' expression { $$ = create_operation_node('<', 2, $1, $3); }
    | expression '>' expression { $$ = create_operation_node('>', 2, $1, $3); }
    | expression GE expression { $$ = create_operation_node(GE, 2, $1, $3); }
    | expression LE expression { $$ = create_operation_node(LE, 2, $1, $3); }
    | expression NE expression { $$ = create_operation_node(NE, 2, $1, $3); }
    | expression EQ expression { $$ = create_operation_node(EQ, 2, $1, $3); }
    ;

%%

Node *create_integer_number_node(int value) {
    Node *node;

    if ((node = malloc(sizeof(Node))) == NULL)
        yyerror("Out of memory");

    node->type = NUMBER_TYPE;
    node->number.type = INTEGER_TYPE;
    node->number.integer_value = value;

    return node;
}

Node *create_float_number_node(float value) {
    Node *node;

    if ((node = malloc(sizeof(Node))) == NULL)
        yyerror("Out of memory");

    node->type = NUMBER_TYPE;
    node->number.type = FLOAT_TYPE;
    node->number.float_value = value;
    
    return node;
}

Node *create_identifier_node(string key, identifier_type = VARIABLE_TYPE) {
    Node *node;

    if ((node = malloc(sizeof(Node))) == NULL)
        yyerror("Out of memory");

    node->type = IDENTIFIER_TYPE;
    node->identifier.key = key;
    node->identifier.type = identifier_type;
    
    return node;
}

Node *create_operation_node(int operation_token, int num_of_operands, ...) {
    va_list arguments_list;
    Node *node;

    if ((node = malloc(sizeof(Node) + (num_of_operands - 1) * sizeof(Node *))) == NULL)
        yyerror("Out of memory");
    
    node->type = OPERATION_TYPE;
    node->operation.operator_token = operation_token;
    node->operation.num_of_operands = num_of_operands;
    va_start(arguments_list, num_of_operands);
    for (int i = 0; i < num_of_operands; i++)
        node->operation.operands[i] = va_arg(arguments_list, Node*);
    va_end(arguments_list);

    return node;
}

void generate(Node *node) {
    int label_1, label_2;
    if (!node) return 0;
    switch(node->type) {
        case NUMBER_TYPE:
            switch (node->number.type) {
                case INTEGER_TYPE:
                    printf("\tPUSH\t%d\n", node->number.integer_value);
                    break;
                case FLOAT_TYPE:
                    printf("\tPUSH\t%d\n", node->number.float_value);
                    break;
            }
            break;
        case IDENTIFIER_TYPE:
            printf("\tPUSH\t%s\n", node->identifier.key);
            break;
        case OPERATION_TYPE:
            switch(node->operation.operator_token) {
                case WHILE:
                    printf("L%03d:\n", label_1 = last_used_label++);
                    generate(node->operation.operands[0]);
                    printf("\tJZ\tL%03d\n", label_2 = last_used_label++);
                    generate(node->operation.operands[1]);
                    printf("\tJMP\tL%03d\n", label_1);
                    printf("L%03d:\n", label_2);
                    break;
                case IF:
                    generate(node->operation.operands[0]);
                    if (node->operation.num_of_operands > 2) {
                        printf("\tJZ\tL%03d\n", label_1 = last_used_label++);
                        generate(node->operation.operands[1]);
                        printf("\tJMP\tL%03d\n", label_2 = last_used_label++);
                        printf("L%03d:\n", label_1);
                        generate(node->operation.operands[2]);
                        printf("L%03d:\n", label_2);
                    } else {
                        printf("\tJZ\tL%03d\n", label_1 = last_used_label++);
                        generate(node->operation.operands[1]);
                        printf("L%03d:\n", label_1);
                    }
                    break;
                case '=':
                    generate(node->operation.operands[1]);
                    printf("\tPOP\t%c\n", node->operation.operands[0]->identifier.key);
                    break;
                default:
                    generate(node->operation.operands[0]);
                    generate(node->operation.operands[1]);
                    switch(node->operation.oper) {
                        case '+': printf("\tADD\n"); break;
                        case '-': printf("\tSUB\n"); break;
                        case '*': printf("\tMUL\n"); break;
                        case '/': printf("\tDIV\n"); break;
                        case '<': printf("\tCMPLT\n"); break;
                        case '>': printf("\tCMPGT\n"); break;
                        case GE: printf("\tCMPGE\n"); break;
                        case LE: printf("\tCMPLE\n"); break;
                        case NE: printf("\tCMPNE\n"); break;
                        case EQ: printf("\tCMPEQ\n"); break;
                    }
            }
            break;
    }
}

void free_node(Node *node) {
    if (!node) return;
    if (node->type == OPERATION_TYPE) {
        for (int i = 0; i < node->operation.num_of_operands; i++)
            freeNode(node->operation.operands[i]);
    }
    free(node);
}

void yyerror(char *s) {
    fprintf(stdout, "%s\n", s);
}

int main(void) {
    yyin = fopen("test.kabsa", "r");
    yyparse();
    return 0;
}
