typedef enum { INTEGER_TYPE, FLOAT_TYPE } numberEnum;

typedef struct Number {
    numberEnum type;
    union {
        int integer_value;
        float float_value;
    };
} Number;
