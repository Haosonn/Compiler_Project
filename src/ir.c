#include <stdio.h>
#include "ir.h"

struct IRInstruction* irTableHead;

IRInstruction* createInstruction(IROpCode opcode, const char* operand1, const char* operand2, const char* result) {
    struct IRInstruction* instruction = (struct IRInstruction*)malloc(sizeof(struct IRInstruction));
    instruction->opcode = opcode;
    if (operand1 != NULL) strcpy(instruction->op1, operand1);
    else instruction->op1[0] = '\0'; 
    if (operand2 != NULL) strcpy(instruction->op2, operand2);
    else instruction->op2[0] = '\0';
    if (result != NULL) strcpy(instruction->res, result);
    else instruction->res[0] = '\0';
    instruction->prev = NULL;
    instruction->next = NULL;
    return instruction;
}

IRInstructionList createInstructionList(IRInstruction* ir) {
    struct IRInstructionList irList;
    irList.head = irList.tail = ir;
    return irList;
}

void insertInstructionAfter(IRInstructionList* irList1, IRInstructionList* irList2) {
    if (irList1 == NULL || irList2 == NULL) {
        printf("in insertInstructionAfter, irList1 or irList2 is NULL\n");
        return;
    }
    if (irList1->tail == NULL) {
        irList1->head = irList2->head;
        irList1->tail = irList2->tail;
        return;
    }
    if (irList2->head == NULL) {
        return;
    }
    irList1->tail->next = irList2->head;
    irList2->head->prev = irList1->tail;
    irList1->tail = irList2->tail;
}

void print_ir(IRInstruction *ir) {
    if (ir == NULL) {
        printf("in print_ir, ir is NULL\n");
        return;
    }
    switch (ir->opcode) {
        case IR_OP_ADD:
            printf("%s := %s + %s\n", ir->res, ir->op1, ir->op2);
            break;
        case IR_OP_SUB:
            printf("%s := %s - %s\n", ir->res, ir->op1, ir->op2);
            break;
        case IR_OP_MUL:
            printf("%s := %s * %s\n", ir->res, ir->op1, ir->op2);
            break;
        case IR_OP_DIV:
            printf("%s := %s / %s\n", ir->res, ir->op1, ir->op2);
            break;
        case IR_OP_ASSIGN:
            printf("%s := %s\n", ir->res, ir->op1);
            break;
        case IR_OP_GOTO:
            printf("goto %s\n", ir->res);
            break;
        case IR_OP_IF_EQ_GOTO:
            printf("if %s == %s goto %s\n", ir->op1, ir->op2, ir->res);
            break;
        case IR_OP_LABEL:
            printf("%s(label name):\n", ir->res);
            break;
        case IR_OP_RETURN:
            printf("return %s\n", ir->res);
            break;
        case IR_OP_READ:
            printf("read %s\n", ir->res);
            break;
        case IR_OP_WRITE:
            printf("write %s\n", ir->res);
            break;
        case IR_OP_CALL:
            printf("%s := call %s(function name)\n", ir->res, ir->op1);
            break;
        case IR_OP_ARG:
            printf("arg %s\n", ir->res);
            break;
        case IR_OP_PARAM:
            printf("param %s\n", ir->res);
            break;
        case IR_OP_GET_ADDR:
            printf("%s := &%s\n", ir->res, ir->op1);
            break;
        case IR_OP_GET_VALUE:
            printf("%s := *%s\n", ir->res, ir->op1);
            break;
        case IR_OP_FUNC:
            printf("function %s:\n", ir->res);
            break;
        default:
            printf("Unknown opcode\n");
    }
}
void print_ir_list(IRInstructionList irList) {
#ifndef PRINT_IR 
    return;
#endif
    IRInstruction* ir = irList.head;
    int i = 1;
    while (ir != NULL) {
        print_ir(ir);
        ir = ir->next;
        i++;
    }
}

