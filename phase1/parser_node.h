#pragma once
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

typedef struct ParserNode{
    char name[20];
    int line;
    int child_num;
    struct ParserNode *child[10];
    union parser_node_value
    {
        int int_value;
        float float_value;
        char* string_value;
    } value;
    
} ParserNode;

void addParserNode(struct ParserNode *node, struct ParserNode *child) {
    node->child[node->child_num++] = child;
}
ParserNode* initParserNode(const char *name) {
    ParserNode * node = (struct ParserNode*)malloc(sizeof(struct ParserNode));
    strcpy(node->name, name);
    node->line = 0;
    node->child_num = 0;
    // printf("initParserNode: %s at address %p\n", name, node);
    return node;
}
void printParserNode(struct ParserNode *node, int depth) {
    // print tabs according to depth
    for (int i = 0; i < depth; i++) {
        printf("  ");
    }
    printf("%s", node->name);
    if (strcmp(node->name, "INT") == 0) {
        printf(": %d", node->value.int_value);
    }
    if (strcmp(node->name, "FLOAT") == 0) {
        printf(": %f", node->value.float_value);
    }
    if (strcmp(node->name, "CHAR") == 0) {
        printf(": '%c'", node->value.int_value);
    }
    if (strcmp(node->name, "ID") == 0) {
        printf(": %s", node->value.string_value);
    }
    if (strcmp(node->name, "TYPE") == 0) {
        printf(": %s", node->value.string_value);
    }
    if (strcmp(node->name, "LITERAL") == 0) {
        printf(": %s", node->value.string_value);
    }
    printf("\n");
    for (int i = 0; i < node->child_num; i++) {
        printParserNode(node->child[i], depth + 1);
    }
}