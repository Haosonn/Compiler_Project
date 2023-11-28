#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "parser_node.h"
#include "symbol_table.h"

typedef struct Type Type;
int type_equal(Type *type1, Type *type2);
int type_same_namespace(Type *type1, Type *type2);
void type_print(Type *type);


SymbolList *symbol_list_init()
{
    SymbolList *list = (SymbolList *)malloc(sizeof(SymbolList));
    list->head = NULL;
    return list;
}

void symbol_list_insert(SymbolList *list, Type *type)
{
    SymbolListNode *node = (SymbolListNode *)malloc(sizeof(SymbolListNode));
    node->type = type;
    node->next = NULL;
    if (list->head == NULL)
    {
        list->head = node;
    }
    else
    {
        node->next = list->head;
        list->head = node;
    }
}

void symbol_list_pop(SymbolList *list)
{
    if (list->head == NULL)
    {
        return;
    }
    SymbolListNode *node = list->head;
    list->head = list->head->next;
    free(node);
}


SymbolTable *symbol_table_init()
{
    SymbolTable *table = (SymbolTable *)malloc(sizeof(SymbolTable));
    table->head = NULL;
    return table;
}

int symbol_table_equal(SymbolTable *table1, SymbolTable *table2)
{
    SymbolTableNode *node1 = table1->head;
    SymbolTableNode *node2 = table2->head;
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

void symbol_table_add_node(SymbolTable *table, SymbolTableNode *node)
{
    SymbolTableNode *node_cpy = (SymbolTableNode *)malloc(sizeof(SymbolTableNode));
    memcpy(node_cpy, node, sizeof(SymbolTableNode));
    node_cpy->next = NULL;
    if (table->head == NULL)
    {
        table->head = node_cpy;
    }
    else
    {
        node_cpy->next = table->head;
        table->head = node_cpy;
    }
}

SymbolTableNode *symbol_table_find(SymbolTable *table, char *name)
{
    SymbolTableNode *node = table->head;
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

void symbol_table_remove(SymbolTable *table, char *name)
{
    SymbolTableNode *node = table->head;
    SymbolTableNode *prev = NULL;
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

void symbol_table_remove_empty(SymbolTable *table)
{
    SymbolTableNode *node = table->head;
    SymbolTableNode *prev = NULL;
    while (node != NULL)
    {
        if (node->list->head == NULL)
        {
            if (node==table->head)
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

SymbolTableNode *symbol_table_insert(SymbolTable *table, char *name, Type *type)
{
    SymbolTableNode *node = symbol_table_find(table, name);
    if (node != NULL)
    {
        symbol_list_insert(node->list, type);
        return node;
    }
    node = (SymbolTableNode *)malloc(sizeof(SymbolTableNode));
    node->name = name;
    node->list = symbol_list_init();
    symbol_list_insert(node->list, type);
    node->next = NULL;
    if (table->head == NULL)
    {
        table->head = node;
    }
    else
    {
        node->next = table->head;
        table->head = node;
    }
    return node;
}

void symbol_table_print(SymbolTable *table)
{
    SymbolTableNode *node = table->head;
    while (node != NULL)
    {
        SymbolListNode *list_node = node->list->head;
        if (node->list->head == NULL)
        {
            printf("%s \n", node->name);
            node = node->next;
            continue;
        }
        printf("%s: ", node->name);
        type_print(node->list->head->type);
        printf("\n");
        node = node->next;
    }
}


ScopeList *scope_list_init()
{
    ScopeList *list = (ScopeList *)malloc(sizeof(ScopeList));
    list->head = NULL;
    scope_list_add(list);
    return list;
}

void scope_list_add(ScopeList *list)
{
    ScopeListNode *node = (ScopeListNode *)malloc(sizeof(ScopeListNode));
    node->table = symbol_table_init();
    node->next = NULL;
    if (list->head == NULL)
    {
        list->head = node;
    }
    else
    {
        node->next = list->head;
        list->head = node;
    }
}

SymbolTable *scope_list_pop(ScopeList *list)
{
    SymbolTable *table = symbol_table_init();
    if (list->head == NULL)
    {
        return table;
    }
    ScopeListNode *node = list->head;
    list->head = list->head->next;

    SymbolTableNode *table_node = node->table->head;
    while (table_node != NULL)
    {
        symbol_table_insert(table, table_node->name, table_node->list->head->type);
        symbol_list_pop(table_node->list);
        table_node = table_node->next;
    }
    free(node);
    return table;
}

Type *symbol_table_lookup(SymbolTable *table, char *name)
{
    SymbolTableNode *node = table->head;
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
