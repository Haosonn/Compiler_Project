#pragma once
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "parser_node.h"

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

symbol_table *symbol_table_init()
{
    symbol_table *table = (symbol_table *)malloc(sizeof(symbol_table));
    table->head = NULL;
    table->tail = NULL;
    return table;
}

void symbol_table_add_node(symbol_table *table, symbol_table_node *node)
{
    if (table->head == NULL)
    {
        table->head = node;
        table->tail = node;
    }
    else
    {
        table->tail->next = node;
        table->tail = node;
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
        table->tail->next = node;
        table->tail = node;
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

scope_list *scope_list_init()
{
    scope_list *list = (scope_list *)malloc(sizeof(scope_list));
    list->head = NULL;
    list->tail = NULL;
    return list;
}

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
void scope_list_pop(scope_list *list)
{
    if (list->head == NULL)
    {
        return;
    }
    scope_list_node *node = list->head;
    list->head = list->head->next;
    free(node);
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

int symbol_table_declare(scope_list *stack, char *name, Type *type)
{
    symbol_table *table = stack->head->table;
    symbol_table_node *node = symbol_table_find(table, name);
    if (node != NULL)
    {
        return 0;
    }
    symbol_table_add_node(table, symbol_table_insert(table, name, type));
    return 1;
}