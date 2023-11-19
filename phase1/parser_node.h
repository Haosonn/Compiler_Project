#pragma once
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "symbol_table.h"
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
        symbol_table *structure;
        symbol_table *function;
    };
} Type;

typedef struct Array
{
    struct Type *base;
    int size;
} Array;

int type_equal(Type *type1, Type *type2)
{
    if (type1 == NULL || type2 == NULL)
    {
        return 0;
    }
    if (type1->category != type2->category)
    {
        return 0;
    }
    switch (type1->category)
    {
    case PRIMITIVE:
        if (type1->primitive != type2->primitive)
        {
            return 0;
        }
        break;
    case ARRAY:
        if (type1->array->size != type2->array->size)
        {
            return 0;
        }
        if (!type_equal(type1->array->base, type2->array->base))
        {
            return 0;
        }
        break;
    case STRUCTURE:
        if (!symbol_table_equal(type1->structure, type2->structure))
        {
            return 0;
        }
        break;
    case FUNCTION:
        if (!symbol_table_equal(type1->function, type2->function))
        {
            return 0;
        }
        break;
    default:
        break;
    }
    return 1;
}

void type_print(Type *type)
{
    if (type == NULL)
    {
        printf("NULL");
        return;
    }
    switch (type->category)
    {
    case PRIMITIVE:
        switch (type->primitive)
        {
        case SEMANTIC_TYPE_INT:
            printf("int");
            break;
        case SEMANTIC_TYPE_FLOAT:
            printf("float");
            break;
        case SEMANTIC_TYPE_CHAR:
            printf("char");
            break;
        default:
            break;
        }
        break;
    case ARRAY:
        // recursively print
        type_print(type->array->base);
        printf("[%d]", type->array->size);
        break;
    case STRUCTURE:
        printf("struct");
        break;
    default:
        break;
    }
}
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
    } value;

} ParserNode;

void passType(struct ParserNode *node, Type *type)
{
    if (strcat(node->name, "ExtDecList") == 0)
    {
        for (int i = 0; i < node->child_num; i++)
        {
            passType(node->child[i], type);
        }
    }
    if (strcat(node->name, "VarDec") == 0)
    {
        *(node->type) = *type;
    }
}

void addParserNode(struct ParserNode *node, struct ParserNode *child)
{
    node->child[node->child_num++] = child;
}

void setParserNodeType(struct ParserNode *node, char *type_name)
{
    node->type = (struct Type *)malloc(sizeof(struct Type));
    if (strcat(type_name, "int") == 0)
    {
        node->type->category = PRIMITIVE;
        node->type->primitive = SEMANTIC_TYPE_INT;
    }
    else if (strcat(type_name, "float") == 0)
    {
        node->type->category = PRIMITIVE;
        node->type->primitive = SEMANTIC_TYPE_FLOAT;
    }
    else if (strcat(type_name, "char") == 0)
    {
        node->type->category = PRIMITIVE;
        node->type->primitive = SEMANTIC_TYPE_CHAR;
    }
}

ParserNode *initParserNode(const char *name, int lineno)
{
    ParserNode *node = (struct ParserNode *)malloc(sizeof(struct ParserNode));
    strcpy(node->name, name);
    node->line = lineno;
    node->to_print_lineno = 0;
    node->child_num = 0;
    node->empty_value = 0;
    node->is_left_value = 0;
    memset(node->child, 0, sizeof(node->child));
    node->type=NULL;
    printf("init %s\n", node->name);
    return node;
}

void cal_line(struct ParserNode *node)
{
    node->to_print_lineno = 1;
    // for (int i = 0; i < node->child_num; i++) {
    //     node->line = node->line > node->child[i]->line ? node->child[i]->line : node->line;
    // }
    node->line = node->child[0]->line;
}

void printParserNode(struct ParserNode *node, int depth)
{
    // print tabs according to depth
    if (node == NULL)
        return;
    if (node->empty_value)
        return;
    for (int i = 0; i < depth; i++)
    {
        printf("  ");
    }
    printf("%s", node->name);
    if (node->to_print_lineno == 1)
    {
        printf(" (%d)", node->line);
    }
    if (strcmp(node->name, "INT") == 0)
    {
        printf(": %d", node->value.int_value);
    }
    else if (strcmp(node->name, "FLOAT") == 0)
    {
        // printf(": %f", node->value.float_value);
        printf(": %s", node->value.string_value);
    }
    else if (strcmp(node->name, "CHAR") == 0)
    {
        printf(": %s", node->value.string_value); // some day after the phase test, I will delete this
    }
    else if (strcmp(node->name, "ID") == 0)
    {
        printf(": %s", node->value.string_value);
    }
    else if (strcmp(node->name, "TYPE") == 0)
    {
        printf(": %s", node->value.string_value);
    }
    else if (strcmp(node->name, "LITERAL") == 0)
    {
        printf(": %s", node->value.string_value);
    }
    printf("\n");
    for (int i = 0; i < node->child_num; i++)
    {
        printParserNode(node->child[i], depth + 1);
    }
}
