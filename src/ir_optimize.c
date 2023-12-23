#include <stdio.h>
#include "ir.h"
#include "ir_optimize.h"
#include "parser_node.h"
#include "symbol_table.h"

IrConstantList *irConstantListInit()
{
    IrConstantList *list = (IrConstantList *)malloc(sizeof(IrConstantList));
    list->head = NULL;
    list->tail = NULL;
    return list;
}

void irConstantListPrint(IrConstantList *list)
{
    IrConstantNode *node = list->head;
    while (node != NULL)
    {
        printf("name: %s, value: %d, op: %s\n", node->name, node->value, node->op);
        node = node->next;
    }
}

IrConstantNode *irConstantListFind(IrConstantList *list, char *name)
{
    IrConstantNode *node = list->head;
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

void irConstantListAdd(IrConstantList *list, char *name, int value)
{
    IrConstantNode *node = irConstantListFind(list, name);
    if (node != NULL)
    {
        node->value = value;
        return;
    }
    node = (IrConstantNode *)malloc(sizeof(IrConstantNode));
    node->name = name;
    node->value = value;
    node->next = NULL;
    node->prev = list->tail;
    if (list->head == NULL)
    {
        list->head = node;
    }
    if (list->tail != NULL)
    {
        list->tail->next = node;
    }
    list->tail = node;
}
void irConstantListAddOp(IrConstantList *list, char *name, char *op)
{
    IrConstantNode *node = irConstantListFind(list, name);
    if (node != NULL)
    {
        node->op = op;
        return;
    }
    node = (IrConstantNode *)malloc(sizeof(IrConstantNode));
    node->name = name;
    node->op = op;
    node->next = NULL;
    node->prev = list->tail;
    if (list->head == NULL)
    {
        list->head = node;
    }
    if (list->tail != NULL)
    {
        list->tail->next = node;
    }
    list->tail = node;
}

void irConstantListRemove(IrConstantList *list, char *name)
{
    IrConstantNode *node = irConstantListFind(list, name);
    if (node == NULL)
    {
        return;
    }
    if (node->prev != NULL)
    {
        node->prev->next = node->next;
    }
    else
    {
        list->head = node->next;
    }
    if (node->next != NULL)
    {
        node->next->prev = node->prev;
    }
    else
    {
        list->tail = node->prev;
    }
}
int isConstantOp(char *op)
{
    return op[0] == '#' && op[1] != '\0';
}
int isLeadingInstruction(IRInstruction *IRInstruction)
{
    return IRInstruction->opcode == IR_OP_LABEL || IRInstruction->opcode == IR_OP_FUNC || IRInstruction->prev != NULL && (IRInstruction->prev->opcode == IR_OP_GOTO || IRInstruction->prev->opcode == IR_OP_IF_EQ_GOTO || IRInstruction->prev->opcode == IR_OP_IF_LT_GOTO || IRInstruction->prev->opcode == IR_OP_IF_LEQ_GOTO || IRInstruction->prev->opcode == IR_OP_RETURN);
}
int isOpInstruction(IRInstruction *IRInstruction)
{
    return IRInstruction->opcode == IR_OP_ADD || IRInstruction->opcode == IR_OP_SUB || IRInstruction->opcode == IR_OP_MUL || IRInstruction->opcode == IR_OP_DIV;
}

int isAssiInstruction(IRInstruction *IRInstruction)
{
    return IRInstruction->opcode == IR_OP_ASSIGN || IRInstruction->opcode == IR_OP_GET_ADDR || IRInstruction->opcode == IR_OP_GET_VALUE || IRInstruction->opcode == IR_OP_ASSIGN_ADDR;
}

void doConstantOptimization(IRInstructionList *iRInstructionList)
{
    IRInstruction *ir = iRInstructionList->head;
    IrConstantList *irConstantList = irConstantListInit();
    while (ir != NULL)
    {
        if (isLeadingInstruction(ir))
        {
            irConstantList = irConstantListInit();
        }
        if (isOpInstruction(ir))
        {
            IrConstantNode *op1 = irConstantListFind(irConstantList, ir->op1);
            IrConstantNode *op2 = irConstantListFind(irConstantList, ir->op2);
            if ((op1 != NULL || isConstantOp(ir->op1)) && (op2 != NULL || isConstantOp(ir->op2)))
            {
                int value;
                int value1 = op1 != NULL ? op1->value : atoi(ir->op1 + 1);
                int value2 = op2 != NULL ? op2->value : atoi(ir->op2 + 1);
                switch (ir->opcode)
                {
                case IR_OP_ADD:
                    value = value1 + value2;
                    break;
                case IR_OP_SUB:
                    value = value1 - value2;
                    break;
                case IR_OP_MUL:

                    value = value1 * value2;
                    break;
                case IR_OP_DIV:
                    value = value1 / value2;
                    break;
                default:
                    break;
                }
                irConstantListAdd(irConstantList, ir->res, value);
                iRInstructionListRemove(iRInstructionList, ir);
            }
            else
            {
                if (irConstantListFind(irConstantList, ir->res) != NULL)
                {
                    irConstantListRemove(irConstantList, ir->res);
                }
            }
        }
        else if (isAssiInstruction(ir))
        {
            IrConstantNode *op1 = irConstantListFind(irConstantList, ir->op1);
            if (op1 != NULL || isConstantOp(ir->op1))
            {
                int value = op1 != NULL ? op1->value : atoi(ir->op1 + 1);
                irConstantListAdd(irConstantList, ir->res, value);
            }
            else
            {
                if (irConstantListFind(irConstantList, ir->res) != NULL)
                {
                    irConstantListRemove(irConstantList, ir->res);
                }
            }
        }
        else
        {
            IrConstantNode *op1 = irConstantListFind(irConstantList, ir->op1);
            IrConstantNode *op2 = irConstantListFind(irConstantList, ir->op2);
            IrConstantNode *res = irConstantListFind(irConstantList, ir->res);
            if (op1 != NULL)
            {
                sprintf(ir->op1, "#%d", op1->value);
            }
            if (op2 != NULL)
            {
                sprintf(ir->op2, "#%d", op2->value);
            }
            if (res != NULL)
            {
                sprintf(ir->res, "#%d", res->value);
            }
        }
        ir = ir->next;
    }
}

void doCopyPropagation(IRInstructionList *iRInstructionList)
{
    IRInstruction *ir = iRInstructionList->head;
    IrConstantList *irConstantList = irConstantListInit();
    while (ir != NULL)
    {
        if (isLeadingInstruction(ir))
        {
            irConstantList = irConstantListInit();
        }
        if (isAssiInstruction(ir))
        {
            IrConstantNode *op1 = irConstantListFind(irConstantList, ir->op1);
            if (op1 != NULL)
            {
                memcpy(ir->op1, op1->op, strlen(op1->op) + 1);
            }
            irConstantListAddOp(irConstantList, ir->res, ir->op1);
        }
        else
        {
            IrConstantNode *op1 = irConstantListFind(irConstantList, ir->op1);
            IrConstantNode *op2 = irConstantListFind(irConstantList, ir->op2);
            IrConstantNode *res = irConstantListFind(irConstantList, ir->res);
            if (op1 != NULL)
            {
                memcpy(ir->op1, op1->op, strlen(op1->op) + 1);
            }
            if (op2 != NULL)
            {
                memcpy(ir->op2, op2->op, strlen(op2->op) + 1);
            }
            if (res != NULL)
            {
                memcpy(ir->res, res->op, strlen(res->op) + 1);
            }
        }
        ir = ir->next;
    }
}

void doReferenceCnt(IRInstructionList *iRInstructionList)
{
    IRInstruction *ir = iRInstructionList->head;
    IrConstantList *irConstantList = irConstantListInit();
    while (ir != NULL)
    {
        if (ir->op1 != NULL)
        {
            irConstantListAdd(irConstantList, ir->op1, 0);
        }
        if (ir->op2 != NULL)
        {
            irConstantListAdd(irConstantList, ir->op2, 0);
        }
        ir = ir->next;
    }
    ir = iRInstructionList->head;
    while (ir != NULL)
    {
        if (isOpInstruction(ir) || isAssiInstruction(ir))
        {
            if (irConstantListFind(irConstantList, ir->res) == NULL)
            {
                iRInstructionListRemove(iRInstructionList, ir);
            }
        }
        ir = ir->next;
    }
}