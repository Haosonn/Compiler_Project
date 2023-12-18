#define IR_VAR_DEC IRInstructionList ir1;\
                IRInstructionList ir2;\
                IRInstructionList ir3;\
                IRInstructionList ir4;\
                IRInstructionList ir5;\
                IRInstructionList ir6;\
                IRInstructionList ir7;\
                SymbolListNode *sln;\
                int tp = -1, t1 = -1, t2 = -1, lb1 = -1, lb2 = -1, lb3 = -1;


#include <stdio.h>
#include "ir.h"
#include "ir_translate.h"
#include "parser_node.h"
#include "symbol_table.h"

int label_cnt = 0;
int place_cnt = 0;

char op1[OP_LEN_MAX]; char op2[OP_LEN_MAX]; char res[OP_LEN_MAX];
IRInstructionList ir_null = {NULL, NULL};

int new_place() {
    return ++place_cnt;
}

int new_label() {
    return ++label_cnt;
}

IRInstructionList translate_exp(ParserNode* parserNode, int place) {
    IR_VAR_DEC;
    if (parserNode == NULL) {
        printf("in translate_exp, parserNode is NULL\n");
        return ir_null;
    }
    if (parserNode->value.exp_type >= EXP_TYPE_COND_EQ) { // condition expression
        int lb1 = new_label();
        int lb2 = new_label();
        sprintf(op1, "#0");
        sprintf(res, "p%d", place);
        ir1 = createInstructionList(createInstruction(IR_OP_ASSIGN, op1, NULL, res));
        ir2 = translate_cond_exp(parserNode, lb1, lb2);
        sprintf(res, "lb%d", lb1);
        ir3 = createInstructionList(createInstruction(IR_OP_LABEL, NULL, NULL, res));
        sprintf(res, "p%d", place);
        sprintf(op1, "#1");
        ir4 = createInstructionList(createInstruction(IR_OP_ASSIGN, op1, NULL, res));
        sprintf(res, "lb%d", lb2);
        ir5 = createInstructionList(createInstruction(IR_OP_LABEL, NULL, NULL, res));
        insertInstructionAfter(&ir1, &ir2); insertInstructionAfter(&ir1, &ir3); insertInstructionAfter(&ir1, &ir4); insertInstructionAfter(&ir1, &ir5);
        return ir1;
    }
    switch (parserNode->value.exp_type)
    {
        case EXP_TYPE_INT: // int
            int int_value = parserNode->value.int_value;
            sprintf(op1, "#%d", int_value);
            sprintf(res, "p%d", place);
            return createInstructionList(createInstruction(IR_OP_ASSIGN, op1, NULL, res));
            break;
        case EXP_TYPE_ID: // ID
            // sln = symbol_table_lookup(global_table, parserNode->value.string_value);
            sln = parserNode->child[0]->symbolListNode;
            sprintf(op1, "s%d", sln->sym_id);
            sprintf(res, "p%d", place);
            return createInstructionList(createInstruction(IR_OP_ASSIGN, op1, NULL, res));
            break;
        case EXP_TYPE_ASSIGN: // exp ASSIGN exp
            // sln = symbol_table_lookup(global_table, parserNode->child[0]->value.string_value);
            // sln = parserNode->child[0]->symbolListNode;
            if (sln == NULL) {
                printf("in translate_exp, symbol_table_lookup error\n");
                printf("symbol name: %s\n", parserNode->child[0]->value.string_value);
                return ir_null;
            }
            tp = new_place();
            ir1 = translate_exp(parserNode->child[2], tp);
            sprintf(op1, "p%d", tp);
            sprintf(res, "s%d", sln->sym_id);
            ir2 = createInstructionList(createInstruction(IR_OP_ASSIGN, op1, NULL, res));
            sprintf(op1, "s%d", sln->sym_id);
            sprintf(res, "p%d", place);
            ir3 = createInstructionList(createInstruction(IR_OP_ASSIGN, op1, NULL, res));
            insertInstructionAfter(&ir1, &ir2); insertInstructionAfter(&ir1, &ir3);
            return ir1;
            break;
        case EXP_TYPE_PLUS: // exp1 PLUS exp2
            t1 = new_place();
            t2 = new_place();
            ir1 = translate_exp(parserNode->child[0], t1);
            ir2 = translate_exp(parserNode->child[2], t2);
            sprintf(op1, "p%d", t1);
            sprintf(op2, "p%d", t2);
            sprintf(res, "p%d", place);
            ir3 = createInstructionList(createInstruction(IR_OP_ADD, op1, op2, res));
            insertInstructionAfter(&ir1, &ir2); insertInstructionAfter(&ir1, &ir3);
            return ir1;
            break;
        case EXP_TYPE_UMINUS: // MINUS exp
            tp = new_place();
            ir1 = translate_exp(parserNode->child[1], tp);
            sprintf(op1, "#0");
            sprintf(op2, "p%d", tp);
            sprintf(res, "p%d", place);
            ir2 = createInstructionList(createInstruction(IR_OP_SUB, op1, op2, res));
            insertInstructionAfter(&ir1, &ir2);
            return ir1;
            break;
        case EXP_TYPE_READ: // READ LP RP
            sprintf(res, "p%d", place);
            return createInstructionList(createInstruction(IR_OP_READ, NULL, NULL, res));
            break;
        case EXP_TYPE_WRITE: // WRITE LP exp RP
            tp = new_place();
            ir1 = translate_exp(parserNode->child[2], tp);
            sprintf(res, "p%d", tp);
            ir2 = createInstructionList(createInstruction(IR_OP_WRITE, NULL, NULL, res));
            insertInstructionAfter(&ir1, &ir2);
        case EXP_TYPE_CALL: // ID LP RP
            sprintf(res, "%s", parserNode->value.string_value);
            return createInstructionList(createInstruction(IR_OP_CALL, NULL, NULL, res));
            break;
        case EXP_TYPE_CALL_ARGS: // ID LP ARGS RP
            int args_list[10]; //dont wanna allocate dynamically
            int args_cnt = 0;
            memset(args_list, 0, sizeof(args_list));
            ir1 = translate_args(parserNode->child[2], args_list, &args_cnt);
            for (int i = args_cnt - 1; i >= 0; i--) {
                sprintf(res, "p%d", args_list[i]);
                ir2 = createInstructionList(createInstruction(IR_OP_ARG, NULL, NULL, res));
                insertInstructionAfter(&ir1, &ir2);
            }
            sprintf(op1, "%s", parserNode->value.string_value);
            sprintf(res, "p%d", place);
            ir3 = createInstructionList(createInstruction(IR_OP_CALL, op1, NULL, res));
            insertInstructionAfter(&ir1, &ir3);
            return ir1;
            break;
        default:
            printf("translate_exp error\n");
            break;
    }
}

IRInstructionList translate_cond_exp(ParserNode* parserNode, int lb_true, int lb_false) {
    IR_VAR_DEC;
    switch (parserNode->value.exp_type)
    {
        case EXP_TYPE_COND_EQ: // exp1 EQ exp2
            t1 = new_place();
            t2 = new_place();
            ir1 = translate_exp(parserNode->child[0], t1);
            ir2 = translate_exp(parserNode->child[2], t2);
            sprintf(op1, "p%d", t1);
            sprintf(op2, "p%d", t2);
            sprintf(res, "lb%d", lb_true);
            ir3 = createInstructionList(createInstruction(IR_OP_IF_EQ_GOTO, op1, op2, res));
            sprintf(res, "lb%d", lb_false);
            ir4 = createInstructionList(createInstruction(IR_OP_GOTO, NULL, NULL, res));
            insertInstructionAfter(&ir1, &ir2); insertInstructionAfter(&ir1, &ir3); insertInstructionAfter(&ir1, &ir4);
            return ir1;
            break;
        case EXP_TYPE_COND_AND: // exp1 AND exp2
            lb1 = new_label();
            ir1 = translate_cond_exp(parserNode->child[0], lb1, lb_false);
            sprintf(res, "lb%d", lb1);
            ir2 = createInstructionList(createInstruction(IR_OP_LABEL, NULL, NULL, res));
            ir3 = translate_cond_exp(parserNode->child[2], lb_true, lb_false);
            insertInstructionAfter(&ir1, &ir2); insertInstructionAfter(&ir1, &ir3);
            return ir1;
            break;
        case EXP_TYPE_COND_OR: // exp1 OR exp2
            lb1 = new_label();
            ir1 = translate_cond_exp(parserNode->child[0], lb_true, lb1);
            sprintf(res, "lb%d", lb1);
            ir2 = createInstructionList(createInstruction(IR_OP_LABEL, NULL, NULL, res));
            ir3 = translate_cond_exp(parserNode->child[2], lb_true, lb_false);
            insertInstructionAfter(&ir1, &ir2); insertInstructionAfter(&ir1, &ir3);
            return ir1;
            break;
        case EXP_TYPE_COND_NOT: // NOT exp
            ir1 = translate_cond_exp(parserNode->child[1], lb_false, lb_true);
            return ir1;
            break;
        default:
            printf("translate_cond_exp error\n");
            break;
    }
}

IRInstructionList translate_stmt(ParserNode* parserNode) {
    IR_VAR_DEC;
    switch (parserNode->value.stmt_type) {
        case STMT_TYPE_EXP: // exp SEMI
            tp = new_place();
            ir1 = translate_exp(parserNode->child[0], tp);
            return ir1;
            break;
        case STMT_TYPE_RETURN: // RETURN exp SEMI
            tp = new_place();
            ir1 = translate_exp(parserNode->child[1], tp);
            sprintf(res, "p%d", tp);
            ir2 = createInstructionList(createInstruction(IR_OP_RETURN, res, NULL, NULL));
            insertInstructionAfter(&ir1, &ir2);
            return ir1;
            break;
        case STMT_TYPE_IF: // IF LP exp RP stmt
            lb1 = new_label();
            lb2 = new_label();
            ir1 = translate_cond_exp(parserNode->child[2], lb1, lb2);
            sprintf(res, "lb%d", lb1);
            ir2 = createInstructionList(createInstruction(IR_OP_LABEL, NULL, NULL, res));
            ir3 = translate_stmt(parserNode->child[4]);
            sprintf(res, "lb%d", lb2);
            ir4 = createInstructionList(createInstruction(IR_OP_LABEL, NULL, NULL, res));
            insertInstructionAfter(&ir1, &ir2); insertInstructionAfter(&ir1, &ir3); insertInstructionAfter(&ir1, &ir4);
            return ir1;
            break;
        case STMT_TYPE_IF_ELSE: // IF LP exp RP stmt ELSE stmt
            lb1 = new_label();
            lb2 = new_label();
            lb3 = new_label();
            ir1 = translate_cond_exp(parserNode->child[2], lb1, lb2);
            sprintf(res, "lb%d", lb1);
            ir2 = createInstructionList(createInstruction(IR_OP_LABEL, NULL, NULL, res));
            ir3 = translate_stmt(parserNode->child[4]);
            sprintf(res, "lb%d", lb3);
            ir4 = createInstructionList(createInstruction(IR_OP_GOTO, NULL, NULL, res));
            sprintf(res, "lb%d", lb2);
            ir5 = createInstructionList(createInstruction(IR_OP_LABEL, NULL, NULL, res));
            ir6 = translate_stmt(parserNode->child[6]);
            sprintf(res, "lb%d", lb3);
            ir7 = createInstructionList(createInstruction(IR_OP_LABEL, NULL, NULL, res));
            insertInstructionAfter(&ir1, &ir2); insertInstructionAfter(&ir1, &ir3); insertInstructionAfter(&ir1, &ir4); insertInstructionAfter(&ir1, &ir5); insertInstructionAfter(&ir1, &ir6); insertInstructionAfter(&ir1, &ir7);
            return ir1;
            break;
        case STMT_TYPE_WHILE: // WHILE LP exp RP stmt
            lb1 = new_label();
            lb2 = new_label();
            lb3 = new_label();
            sprintf(res, "lb%d", lb1);
            ir1 = createInstructionList(createInstruction(IR_OP_LABEL, NULL, NULL, res));
            ir2 = translate_cond_exp(parserNode->child[2], lb2, lb3);
            sprintf(res, "lb%d", lb2);
            ir3 = createInstructionList(createInstruction(IR_OP_LABEL, NULL, NULL, res));
            ir4 = translate_stmt(parserNode->child[4]);
            sprintf(res, "lb%d", lb1);
            ir5 = createInstructionList(createInstruction(IR_OP_GOTO, NULL, NULL, res));
            sprintf(res, "lb%d", lb3);
            ir6 = createInstructionList(createInstruction(IR_OP_LABEL, NULL, NULL, res));
            insertInstructionAfter(&ir1, &ir2); insertInstructionAfter(&ir1, &ir3); insertInstructionAfter(&ir1, &ir4); insertInstructionAfter(&ir1, &ir5); insertInstructionAfter(&ir1, &ir6);
            return ir1;
            break;
        default:
            printf("translate_stmt error\n");
            return ir_null;
            break;
    }
}

IRInstructionList translate_args(ParserNode *parserNode, int* args_list, int *args_cnt) {
    IR_VAR_DEC;
    switch (parserNode->value.args_type)
    {
        case ARGS_TYPE_ARG: // exp
            tp = new_place();
            ir1 = translate_exp(parserNode->child[0], tp);
            args_list[(*args_cnt)++] = tp;
            return ir1;
            break;
        case ARGS_TYPE_ARGS: // exp COMMA args
            tp = new_place();
            ir1 = translate_exp(parserNode->child[0], tp);
            args_list[(*args_cnt)++] = tp;
            ir2 = translate_args(parserNode->child[2], args_list, args_cnt);
            insertInstructionAfter(&ir1, &ir2);
            return ir1;
            break;
        default:
            printf("translate_args error\n");
            return ir_null;
            break;
    }
}

IRInstructionList translate_stmt_list(ParserNode *parserNode) {
    IR_VAR_DEC;
    if (parserNode == NULL) {
        printf("in translate_stmt_list, parserNode is NULL\n");
        return ir_null;
    }
    if (parserNode->empty_value) {
        return ir_null;
    }
    ParserNode *stmt = parserNode->child[0];
    ParserNode *stmt_list = parserNode->child[1];
    ir1 = translate_stmt(stmt);
    ir2 = translate_stmt_list(stmt_list);
    insertInstructionAfter(&ir1, &ir2);
    return ir1;
}

IRInstructionList translate_comp_st(ParserNode *parserNode) {
    IR_VAR_DEC;
    if (parserNode == NULL) {
        printf("in translate_comp_st, parserNode is NULL\n");
        return ir_null;
    }
    if (parserNode->empty_value) {
        return ir_null;
    }
    ParserNode *stmt_list = parserNode->child[2];
    return translate_stmt_list(stmt_list);
}

IRInstructionList translate_ext_def_list(ParserNode *parserNode) {
    IR_VAR_DEC;
    if (parserNode == NULL) {
        printf("in translate_extdef_list, parserNode is NULL\n");
        return ir_null;
    }
    if (parserNode->empty_value) {
        return ir_null;
    }
    ParserNode *ext_def = parserNode->child[0];
    ParserNode *ext_def_list = parserNode->child[1];
    if (ext_def->value.exp_def_type == EXP_DEF_TYPE_VARDEC) { // ExtDef <- Specifier ExtDecList SEMI
        // do nothing
    } else if (ext_def->value.exp_def_type == EXP_DEF_TYPE_FUNDEC) { // ExtDef <- Specifier FunDec CompSt
        sprintf(res, "%s", ext_def->child[1]->child[0]->value.string_value); //FunDec <- ID LP RP
        ir1 = createInstructionList(createInstruction(IR_OP_FUNC, NULL, NULL, res)); 
        ir2 = translate_comp_st(ext_def->child[2]);
        ir3 = translate_ext_def_list(ext_def_list);
        insertInstructionAfter(&ir1, &ir2); insertInstructionAfter(&ir1, &ir3);
        return ir1;
    } else {
        printf("in translate_extdef_list, extdef->value.expdef_type error\n");
    }
    return ir_null;
}

IRInstructionList translate_program(ParserNode *parserNode) {
    IR_VAR_DEC;
    if (parserNode == NULL) {
        printf("in translate_program, parserNode is NULL\n");
        return ir_null;
    }
    if (parserNode->empty_value) {
        printf("in translate_program, parserNode is empty\n");
        return ir_null;
    }
    ParserNode *extdef_list = parserNode->child[0];
    ir1 = translate_ext_def_list(extdef_list);
    print_ir_list(ir1);
    return ir1;
}

