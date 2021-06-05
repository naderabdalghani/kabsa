#include <string>

typedef enum { INTEGER_TYPE, FLOAT_TYPE } numberEnum;
typedef enum { CONSTANT_TYPE, VARIABLE_TYPE, FUNCTION_TYPE } identifierEnum;
typedef enum { NUMBER_TYPE, IDENTIFIER_TYPE, OPERATION_TYPE } nodeEnum;

typedef struct {
    numberEnum type;
    union {
        int integer_value;
        float float_value;
    };
} NumberNode;

typedef struct {
    identifierEnum type;
    std::string key;
} IdentifierNode;

typedef struct {
    int operator_token;
    int num_of_operands;
    struct NodeType *operands[1];
} OperationNode;

typedef struct Node {
    nodeEnum type;
    union {
        NumberNode number;
        IdentifierNode identifier;
        OperationNode operation;
    };
} Node;