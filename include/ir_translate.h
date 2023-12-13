#pragma once
#ifndef IR_TRANSLATE_H
#define IR_TRANSLATE_H
#include <stdint.h>

enum EXP_TYPE {
    EXP_TYPE_INT, // int
    EXP_TYPE_ID, // id
    EXP_TYPE_ASSIGN, // exp1 assign exp2
    EXP_TYPE_PLUS, // exp1 plus exp2
    EXP_TYPE_MINUS, // minus exp
    EXP_TYPE_COND // cond exp
};

enum COND_EXP_TYPE {
    EXP_TYPE_EXP_EQ_EXP,
    EXP_TYPE_EXP_AND_EXP,
    EXP_TYPE_EXP_OR_EXP,
    EXP_TYPE_NOT_EXP
};

enum STMT_TYPE {
    STMT_TYPE_RETURN, // return exp semi
    STMT_TYPE_IF, // if (exp) stmt
    STMT_TYPE_IF_ELSE, // if (exp) stmt else stmt
    STMT_TYPE_WHILE, // while (exp) stmt
};

void translate_exp(uint32_t _exp_type, uint32_t _place);
void translate_cond_exp(uint32_t _exp_type, uint32_t _place);
void translate_stmt(uint32_t _stmt_type);


#endif