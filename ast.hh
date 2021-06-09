#include <string>
#include <vector>


namespace kabsa {
    typedef enum { CONSTANT_TYPE, VARIABLE_TYPE, FUNCTION_TYPE } identifierEnum;
    typedef enum { NUMBER_TYPE, IDENTIFIER_TYPE, OPERATION_TYPE } nodeEnum;

    class Node {
        private:
            nodeEnum node_type;
        public:
            Node(nodeEnum node_type) : node_type(node_type) {}
            virtual ~Node() {}
            virtual nodeEnum getNodeType() { return this->node_type; }
    };

    class OperationNode : public Node {
        private:
            int operator_token;
            std::vector<Node *> operands;
        public:
            OperationNode(int operator_token) : Node(OPERATION_TYPE), operator_token(operator_token) {}
            int getOperatorToken() { return this->operator_token; }
            void addOperandNode(Node * operand) { this->operands.push_back(operand); }
            Node *getOperandNode(int index) { return this->operands.at(index); }
            int getNumberOfOperands() { return this->operands.size(); }
    };

    class IdentifierNode : public Node {
        private:
            identifierEnum identifier_type;
            std::string key;
        public:
            IdentifierNode(identifierEnum identifier_type, std::string key) : Node(IDENTIFIER_TYPE), identifier_type(identifier_type), key(key) {}
            void setIdentifierType(identifierEnum identifier_type) { this->identifier_type = identifier_type; }
            identifierEnum getIdentifierType() { return this->identifier_type; }
            std::string getKey() { return this->key; }
    };

    template <typename T>
    class NumberNode : public Node {
        private:
            T value;
        public:
            NumberNode(T value) : Node(NUMBER_TYPE), value(value) {}
            T getValue() { return this->value; }
    };
}
