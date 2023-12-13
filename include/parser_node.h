#pragma once
#ifndef PARSER_NODE_H
#include "symbol_table.h"
#include "ir_translate.h"
typedef struct ParserNode
{
    char name[20];
    int line;
    int to_print_lineno;
    int child_num;
    int empty_value;
    int is_left_value;
    struct ParserNode *child[10];
    struct Type *type;
    union parser_node_value
    {
        int int_value;
        float float_value;
        char *string_value;
        EXP_TYPE exp_type;
        COND_EXP_TYPE cond_exp_type;
        STMT_TYPE stmt_type;
    } value;

} ParserNode;

typedef struct Type
{
    enum
    {
        PRIMITIVE,
        ARRAY,
        STRUCTURE,
        FUNCTION
    } category;
    union
    {
        enum
        {
            SEMANTIC_TYPE_INT,
            SEMANTIC_TYPE_FLOAT,
            SEMANTIC_TYPE_CHAR
        } primitive;
        struct Array *array;
        SymbolTable *structure;
        SymbolTable *function;
    };
} Type;

typedef struct Array
{
    struct Type *base;
    int size;
} Array;

// int type_same_namespace(Type *type1, Type *type2);

int check_dec_assign_type(struct ParserNode *node, Type *type);
int struct_equal(SymbolTable *struct1, SymbolTable *struct2);
int type_equal(Type *type1, Type *type2);
void type_print(Type *type);
void passType(struct ParserNode *node, Type *type);
void addParserNode(struct ParserNode *node, struct ParserNode *child);
void setParserNodeType(struct ParserNode *node, char *type_name);

ParserNode *initParserNode(const char *name, int lineno);
void cal_line(struct ParserNode *node);
void printParserNode(struct ParserNode *node, int depth);

int var_declare(SymbolTable *global_table, ScopeList *stack, char *name, Type *type);
int function_declare(SymbolTable *global_table, char *name, Type *type);
int check_return_type(ParserNode *ParserNode, Type *type);
int check_function_args(SymbolTable *function, SymbolTable *args);

#endif 