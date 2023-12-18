#pragma once
#ifndef IR_H
#define IR_H
#define OP_LEN_MAX 5

#include <stdio.h>
#include <stdlib.h>
#include <string.h>


typedef enum {
    IR_OP_ADD,
    IR_OP_SUB,
    IR_OP_MUL,
    IR_OP_DIV,
    IR_OP_ASSIGN,
    IR_OP_GOTO,
    IR_OP_IF_EQ_GOTO,
    IR_OP_LABEL,
    IR_OP_RETURN,
    IR_OP_READ,
    IR_OP_WRITE,
    IR_OP_CALL,
    IR_OP_ARG,
    IR_OP_PARAM,
    IR_OP_GET_ADDR,
    IR_OP_GET_VALUE,
    IR_OP_FUNC
} IROpCode;

/*
    IROpCode    |           description
    ------------|---------------------------------
    ADD         |       res := op1 + op2
    SUB         |       res := op1 - op2  
    MUL         |       res := op1 * op2
    DIV         |       res := op1 / op2
    ASSIGN      |       res := op1
    GOTO        |       goto res
    IF_EQ_GOTO  |       if op1 == op2 goto res
    LABEL       |       res(label name) :
    RETURN      |       return res
    READ        |       read res
    WRITE       |       write res
    CALL        |       res := call op1(function name)
    ARG         |       arg res
    PARAM       |       param res
    GET_ADDR    |       res := &op1
    GET_VALUE   |       res := *op1
    FUNC        |       function res:
*/
typedef enum {
    EXP_TYPE_INT, // int
    EXP_TYPE_ID, // id
    EXP_TYPE_ASSIGN, // exp1 assign exp2
    EXP_TYPE_PLUS, // exp1 plus exp2
    EXP_TYPE_UMINUS, // minus exp
    EXP_TYPE_READ, // read id
    EXP_TYPE_WRITE, // write(exp)
    EXP_TYPE_CALL, // id()
    EXP_TYPE_CALL_ARGS, // id(args)
    EXP_TYPE_ARRAY, // id[exp]
    EXP_TYPE_STRUCT, // exp.id
    EXP_TYPE_COND_EQ, // exp1 EQ exp2
    EXP_TYPE_COND_AND, // exp1 AND exp2
    EXP_TYPE_COND_OR, // exp1 OR exp2
    EXP_TYPE_COND_NOT, // NOT exp
} ExpType;

typedef enum {
    STMT_TYPE_EXP, // exp semi
    STMT_TYPE_RETURN, // return exp semi
    STMT_TYPE_IF, // if (exp) stmt
    STMT_TYPE_IF_ELSE, // if (exp) stmt else stmt
    STMT_TYPE_WHILE, // while (exp) stmt
} StmtType;

typedef enum {
    ARGS_TYPE_ARG, // exp
    ARGS_TYPE_ARGS, // exp comma args
} ArgsType;

typedef enum {
    EXP_DEF_TYPE_VARDEC, // Specifier ExtDecList semi
    EXP_DEF_TYPE_FUNDEC, // Specifier FunDec CompSt
} ExpDefType;

typedef struct IRInstruction {
    IROpCode opcode;
    char op1[OP_LEN_MAX];
    char op2[OP_LEN_MAX];
    char res[OP_LEN_MAX];
    struct IRInstruction* prev;
    struct IRInstruction* next;
} IRInstruction;

typedef struct IRInstructionList {
    IRInstruction* head;
    IRInstruction* tail;
} IRInstructionList;


IRInstruction* createInstruction(IROpCode opcode, const char* operand1, const char* operand2, const char* result);
IRInstructionList createInstructionList(IRInstruction* irInstruction);

void insertInstructionAfter(IRInstructionList* irList1, IRInstructionList* irList2);

void print_ir(IRInstruction *ir);
void print_ir_list(IRInstructionList irList);

#endif // IR_H
