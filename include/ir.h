#pragma once
#ifndef IR_H
#define IR_H

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

// Enum representing the opcode types
typedef enum {
    ADD,
    SUB,
    MUL,
    DIV,
    ASSIGN,
    GOTO,
    IF,
    LABEL,
    READ,
    WRITE
} Opcode;

// Struct representing an IR instruction
struct IRInstruction {
    Opcode opcode;
    char operand1[100];
    char operand2[100];
    char result[100];
    struct IRInstruction* prev;
    struct IRInstruction* next;
};

struct IRInstruction* createInstruction(Opcode opcode, const char* operand1, const char* operand2, const char* result);

void insertInstruction(struct IRInstruction** head, struct IRInstruction** tail, struct IRInstruction* instruction);

void deleteInstruction(struct IRInstruction** head, struct IRInstruction** tail, struct IRInstruction* instruction);

void printTable(struct IRInstruction* head);

#endif // IR_H
