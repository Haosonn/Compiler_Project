#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "parser_node.h"
#include "symbol_table.h"

// int type_same_namespace(Type *type1, Type *type2)
// {
//     printf("type1->catagory: %d, type2->catagory: %d\n", type1->category, type2->category);
//     return (type1->category == type2->category ||
//             type1->category == PRIMITIVE && type2->category == ARRAY ||
//             type1->category == ARRAY && type2->category == PRIMITIVE);
// }

int struct_equal(SymbolTable *struct1, SymbolTable *struct2)
{
    SymbolTableNode *node1 = struct1->head;
    SymbolTableNode *node2 = struct2->head;
    while (node1 != NULL && node2 != NULL)
    {
        if (!type_equal(node1->list->head->type, node2->list->head->type))
        {
            return 0;
        }
        node1 = node1->next;
        node2 = node2->next;
    }
    return node1 == NULL && node2 == NULL;
}

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
        // if (type1->array->size != type2->array->size)
        // {
        //     return 0;
        // }
        if (!type_equal(type1->array->base, type2->array->base))
        {
            return 0;
        }
        break;
    case STRUCTURE:
        if (!struct_equal(type1->structure, type2->structure))
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
        printf("[%d]", type->array->size);
        type_print(type->array->base);
        break;
    case STRUCTURE:
        printf("struct {\n");
        symbol_table_print(type->structure);
        printf("}");
        break;
    case FUNCTION:
        printf("function (\n");
        symbol_table_print(type->function);
        printf(")");
        break;
    default:
        break;
    }
}

void passType(struct ParserNode *node, Type *type)
{
    if (strcmp(node->name, "ExtDecList") == 0 ||
        strcmp(node->name, "DecList") == 0)
    {
        for (int i = 0; i < node->child_num; i++)
        {
            passType(node->child[i], type);
        }
    }
    if (strcmp(node->name, "VarDec") == 0 ||
        strcmp(node->name, "Dec") == 0)
    {
        memcpy(node->type, type, sizeof(Type));
    }
}

int check_dec_assign_type(struct ParserNode *node, Type *type)
{
    if (strcmp(node->name, "Exp") == 0)
    {
        return !type_equal(node->type, type);
    }
    else
    {
        for (int i = 0; i < node->child_num; i++)
        {
            if(check_dec_assign_type(node->child[i], type)){
                return 1;
            }
        }
        return 0;
    }
}

void addParserNode(struct ParserNode *node, struct ParserNode *child)
{
    node->child[node->child_num++] = child;
    if (node->type == NULL)
        node->type = child->type;
}

void setParserNodeType(struct ParserNode *node, char *type_name)
{
    node->type = (struct Type *)malloc(sizeof(struct Type));
    if (strcmp(type_name, "int") == 0)
    {
        node->type->category = PRIMITIVE;
        node->type->primitive = SEMANTIC_TYPE_INT;
    }
    else if (strcmp(type_name, "float") == 0)
    {
        node->type->category = PRIMITIVE;
        node->type->primitive = SEMANTIC_TYPE_FLOAT;
    }
    else if (strcmp(type_name, "char") == 0)
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
    node->type = NULL;
    // printf("init %s\n", node->name);
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

int var_declare(SymbolTable *global_table, ScopeList *stack, char *name, Type *type)
{
    SymbolTable *table = stack->head->table;
    SymbolTableNode *node = symbol_table_find(table, name);
    if (node != NULL)
    {
        return 1;
    }
    symbol_table_add_node(table, symbol_table_insert(global_table, name, type));
    return 0;
}

int function_declare(SymbolTable *global_table, char *name, Type *type)
{
    SymbolTableNode *node = symbol_table_find(global_table, name);
    if (node != NULL)
    {
        return 1;
    }
    symbol_table_insert(global_table, name, type);
    return 0;
}

int check_return_type(ParserNode *ParserNode, Type *type)
{
    if (ParserNode == NULL)
        return 1;

    if (strcmp(ParserNode->name, "Stmt") == 0 && strcmp(ParserNode->child[0]->name, "RETURN") == 0)
    {
        if (!type_equal(ParserNode->child[1]->type, type))
        {
            printf("Error type 8 at Line %d: Type mismatched for return.\n", ParserNode->child[0]->line);
        }
        return 0;
    }
    int ret = 1;
    for (int i = 0; i < ParserNode->child_num; i++)
    {
        ret = check_return_type(ParserNode->child[i], type) && ret;
    }
    return ret;
}

int check_function_args(SymbolTable *function, SymbolTable *args)
{
    SymbolTableNode *node1 = function->head->next;
    if (args == NULL)
    {
        return node1 != NULL;
    }
    SymbolListNode *node2 = args->head->list->head;
    while (node1 != NULL && node2 != NULL)
    {
        if (!type_equal(node1->list->head->type, node2->type))
        {
            return 1;
        }
        node1 = node1->next;
        node2 = node2->next;
    }
    return node1 != NULL || node2 != NULL;
}
