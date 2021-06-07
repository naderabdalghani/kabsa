#include <string>
#include <vector>


namespace kabsa {
    typedef enum { INTEGER_TYPE, DOUBLE_TYPE } numberEnum;
    typedef enum { CONSTANT_TYPE, VARIABLE_TYPE, FUNCTION_TYPE } identifierEnum;
    typedef enum { NUMBER_TYPE, IDENTIFIER_TYPE, OPERATION_TYPE } nodeEnum;

    class Node {
        private:
            nodeEnum node_type;
        public:
            Node(nodeEnum node_type) : node_type(node_type) {}
            virtual ~Node() {}
            virtual void setNodeType(nodeEnum node_type) { this->node_type = node_type; }
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
            void setKey(std::string key) { this->key = key; }
    };

    template <typename T>
    class NumberNode : public Node {
        private:
            T value;
            numberEnum number_type;
        public:
            NumberNode(T value) : Node(NUMBER_TYPE), value(value) {
                this->number_type = value == (int)value ? INTEGER_TYPE : DOUBLE_TYPE;
            }
            void setValue(T value) { this->value = value; }
            numberEnum getNumberType() { return this->number_type; }
            T getValue() { return this->value; }
    };
}
