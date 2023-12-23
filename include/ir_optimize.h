#pragma once
#include "ir.h"
#include "parser_node.h"
#include "symbol_table.h"
typedef struct IrConstantNode
{
    struct IrConstantNode *next;
    struct IrConstantNode *prev;
    char *name;
    int value;
} IrConstantNode;
typedef struct IrConstantList
{
    IrConstantNode *head;
    IrConstantNode *tail;
} IrConstantList;
void doConstantOptimization(IRInstructionList *iRInstructionList);
