#pragma once
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "parser_node.h"
typedef struct Type Type;
int type_equal(Type *type1, Type *type2);
int type_same_namespace(Type *type1, Type *type2);
void type_print(Type *type);
typedef struct symbol_list_node
{
    Type *type;
    struct symbol_list_node *next;
} symbol_list_node;

typedef struct symbol_list
{
    symbol_list_node *head;
    symbol_list_node *tail;
} symbol_list;

symbol_list *symbol_list_init()
{
    symbol_list *list = (symbol_list *)malloc(sizeof(symbol_list));
    list->head = NULL;
    list->tail = NULL;
    return list;
}

void symbol_list_insert(symbol_list *list, Type *type)
{
    symbol_list_node *node = (symbol_list_node *)malloc(sizeof(symbol_list_node));
    node->type = type;
    node->next = NULL;
    if (list->head == NULL)
    {
        list->head = node;
        list->tail = node;
    }
    else
    {
        node->next = list->head;
        list->head = node;
    }
}

void symbol_list_pop(symbol_list *list)
{
    if (list->head == NULL)
    {
        return;
    }
    symbol_list_node *node = list->head;
    list->head = list->head->next;
    free(node);
}

typedef struct symbol_table_node
{
    char *name;
    symbol_list *list;
    struct symbol_table_node *next;
} symbol_table_node;

typedef struct symbol_table
{
    symbol_table_node *head;
    symbol_table_node *tail;
} symbol_table;

void symbol_table_print(symbol_table *table)
{
    symbol_table_node *node = table->head;
    printf("Symbol table:\n");
    while (node != NULL)
    {
        printf("%s: ", node->name);
        type_print(node->list->head->type);
        printf("\n");
        node = node->next;
    }
}

int symbol_table_equal(symbol_table *table1, symbol_table *table2)
{
    symbol_table_node *node1 = table1->head;
    symbol_table_node *node2 = table2->head;
    while (node1 != NULL && node2 != NULL)
    {
        if (strcmp(node1->name, node2->name) != 0 || !type_equal(node1->list->head->type, node2->list->head->type))
        {
            return 0;
        }
        node1 = node1->next;
        node2 = node2->next;
    }
    if (node1 != NULL || node2 != NULL)
    {
        return 0;
    }
    return 1;
}

symbol_table *symbol_table_init()
{
    symbol_table *table = (symbol_table *)malloc(sizeof(symbol_table));
    table->head = NULL;
    table->tail = NULL;
    return table;
}

void symbol_table_add_node(symbol_table *table, symbol_table_node *node)
{
    symbol_table_node *node_cpy = (symbol_table_node *)malloc(sizeof(symbol_table_node));
    memcpy(node_cpy, node, sizeof(symbol_table_node));
    node_cpy->next = NULL;
    if (table->head == NULL)
    {
        table->head = node_cpy;
        table->tail = node_cpy;
    }
    else
    {
        table->tail->next = node_cpy;
        table->tail = node_cpy;
    }
}
symbol_table_node *symbol_table_find(symbol_table *table, char *name)
{
    symbol_table_node *node = table->head;
    while (node != NULL)
    {
        if (strcmp(node->name, name) == 0)
        {
            return node;
        }
        node = node->next;
    }
    return NULL;
}

void symbol_table_remove(symbol_table *table, char *name)
{
    symbol_table_node *node = table->head;
    symbol_table_node *prev = NULL;
    while (node != NULL)
    {
        if (strcmp(node->name, name) == 0)
        {
            if (prev == NULL)
            {
                table->head = node->next;
            }
            else
            {
                prev->next = node->next;
            }
            free(node);
            return;
        }
        prev = node;
        node = node->next;
    }
}

void symbol_table_remove_empty(symbol_table *table)
{
    symbol_table_node *node = table->head;
    symbol_table_node *prev = NULL;
    while (node != NULL)
    {
        if (node->list->head == NULL)
        {
            if (prev == NULL)
            {
                table->head = node->next;
            }
            else
            {
                prev->next = node->next;
            }
        }
        prev = node;
        node = node->next;
    }
}

symbol_table_node *symbol_table_insert(symbol_table *table, char *name, Type *type)
{
    symbol_table_node *node = symbol_table_find(table, name);
    if (node != NULL)
    {
        symbol_list_insert(node->list, type);
        return node;
    }
    node = (symbol_table_node *)malloc(sizeof(symbol_table_node));
    node->name = name;
    node->list = symbol_list_init();
    symbol_list_insert(node->list, type);
    node->next = NULL;
    if (table->head == NULL)
    {
        table->head = node;
        table->tail = node;
    }
    else
    {
        node->next = table->head;
        table->head = node;
    }
    return node;
}

typedef struct scope_list_node
{
    symbol_table *table;
    struct scope_list_node *next;
} scope_list_node;

typedef struct scope_list
{
    scope_list_node *head;
    scope_list_node *tail;
} scope_list;

void scope_list_add(scope_list *list)
{
    scope_list_node *node = (scope_list_node *)malloc(sizeof(scope_list_node));
    node->table = symbol_table_init();
    node->next = NULL;
    if (list->head == NULL)
    {
        list->head = node;
        list->tail = node;
    }
    else
    {
        node->next = list->head;
        list->head = node;
    }
}

scope_list *scope_list_init()
{
    scope_list *list = (scope_list *)malloc(sizeof(scope_list));
    list->head = NULL;
    list->tail = NULL;
    scope_list_add(list);
    return list;
}

symbol_table *scope_list_pop(scope_list *list)
{
    symbol_table *table = symbol_table_init();
    if (list->head == NULL)
    {
        return table;
    }
    scope_list_node *node = list->head;
    list->head = list->head->next;
    symbol_table_node *table_node = node->table->head;
    while (table_node != NULL)
    {
        symbol_table_insert(table, table_node->name, table_node->list->head->type);
        symbol_list_pop(table_node->list);
        table_node = table_node->next;
    }
    free(node);
    return table;
}

Type *symbol_table_lookup(symbol_table *table, char *name)
{
    symbol_table_node *node = table->head;
    while (node != NULL)
    {
        if (strcmp(node->name, name) == 0)
        {
            return node->list->head->type;
        }
        node = node->next;
    }
    return NULL;
}
