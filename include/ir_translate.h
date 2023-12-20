#pragma once
#ifndef IR_TRANSLATE_H
#define IR_TRANSLATE_H
#include "ir.h"
#include "parser_node.h"

IRInstructionList translate_exp(ParserNode* parserNode, int place);
IRInstructionList translate_cond_exp(ParserNode* parserNode, int lb_true, int lb_false);
IRInstructionList translate_def_list(ParserNode* parserNode);
IRInstructionList translate_dec_list(ParserNode* parserNode);
IRInstructionList translate_stmt(ParserNode* parserNode);
IRInstructionList translate_stmt_list(ParserNode* parserNode);
IRInstructionList translate_args(ParserNode* parserNode, int* args_list, int *args_cnt);
IRInstructionList translate_comp_st(ParserNode* parserNode);
IRInstructionList translate_args(ParserNode* parserNode, int* args_list, int *args_cnt);
IRInstructionList translate_var_list(ParserNode* parserNode);
IRInstructionList translate_ext_def_list(ParserNode* parserNode);
IRInstructionList translate_program(ParserNode* parserNode);


#endif