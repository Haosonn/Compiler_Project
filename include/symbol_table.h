#pragma once

typedef struct Type Type;
int type_equal(Type *type1, Type *type2);
int type_same_namespace(Type *type1, Type *type2);
void type_print(Type *type);

typedef struct SymbolListNode
{
    Type *type;
    struct SymbolListNode *next;
} SymbolListNode;

typedef struct SymbolList
{
    SymbolListNode *head;
} SymbolList;

typedef struct SymbolTableNode
{
    char *name;
    SymbolList *list;
    struct SymbolTableNode *next;
} SymbolTableNode;

typedef struct SymbolTable
{
    SymbolTableNode *head;
} SymbolTable;

typedef struct ScopeListNode
{
    SymbolTable *table;
    struct ScopeListNode *next;
} ScopeListNode;

typedef struct ScopeList
{
    ScopeListNode *head;
} ScopeList;

SymbolList *symbol_list_init();
void symbol_list_insert(SymbolList *list, Type *type);
void symbol_list_pop(SymbolList *list);

SymbolTable *symbol_table_init();
int symbol_table_equal(SymbolTable *table1, SymbolTable *table2);
void symbol_table_add_node(SymbolTable *table, SymbolTableNode *node);
SymbolTableNode *symbol_table_find(SymbolTable *table, char *name);
void symbol_table_remove(SymbolTable *table, char *name);
void symbol_table_remove_empty(SymbolTable *table);
SymbolTableNode *symbol_table_insert(SymbolTable *table, char *name, Type *type);
void symbol_table_print(SymbolTable *table);

ScopeList *scope_list_init();
void scope_list_add(ScopeList *list);
SymbolTable *scope_list_pop(ScopeList *list);
Type *symbol_table_lookup(SymbolTable *table, char *name);