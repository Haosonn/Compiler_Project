#pragma once
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
typedef struct Type
{
    enum
    {
        PRIMITIVE,
        ARRAY,
        STRUCTURE
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
        struct FieldList *structure;
    };
} Type;

typedef struct Array
{
    struct Type *base;
    int size;
} Array;

typedef struct FieldList
{
    char name[32];
    struct Type *type;
    struct FieldList *next;
} FieldList;

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

void addParserNode(struct ParserNode *node, struct ParserNode *child)
{
    node->child[node->child_num++] = child;
}

void setParserNodeType(struct ParserNode *node, int type)
{
    node->type = (struct Type *)malloc(sizeof(struct Type));
    switch (type)
    {
    case 0:
        node->type->category = PRIMITIVE;
        node->type->primitive = SEMANTIC_TYPE_INT;
        break;
    case 1:
        node->type->category = PRIMITIVE;
        node->type->primitive = SEMANTIC_TYPE_FLOAT;
        break;
    case 2:
        node->type->category = PRIMITIVE;
        node->type->primitive = SEMANTIC_TYPE_CHAR;
        break;
    default:
        break;
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
    // printf("initParserNode: %s at address %p\n", name, node);
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
