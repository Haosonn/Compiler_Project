#define IR_VAR_DEC IRInstructionList ir1 = ir_null;\
                IRInstructionList ir2 = ir_null;\
                IRInstructionList ir3 = ir_null;\
                IRInstructionList ir4 = ir_null;\
                IRInstructionList ir5 = ir_null;\
                IRInstructionList ir6 = ir_null;\
                IRInstructionList ir7 = ir_null;\
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
extern IRInstructionList alloc_ir_list;

int new_place() {
    return ++place_cnt;
}

int new_label() {
    return ++label_cnt;
}

void allocate_var_dec(ParserNode *parserNode) {
    ParserNode *varDec = parserNode;
    while(strcmp(varDec->child[0]->name, "ID")) { // move into the terminal ID where VarDec <- ID
        // otherwise VarDec <- VarDec LB INT RB
        varDec = varDec->child[0];
    }
    ParserNode *id = varDec->child[0];
    SymbolListNode *sln = id->symbolListNode;
    Type *type = sln->type;
    int type_size = calculate_type_size(type);
    char res[OP_LEN_MAX], op1[OP_LEN_MAX];
    sprintf(res, "s%d", sln->sym_id);
    sprintf(op1, "#%d", mem_alloc_cnt);
    IRInstructionList ir_assign = createInstructionList(createInstruction(IR_OP_ASSIGN, op1, NULL, res));
    insertInstructionAfter(&alloc_ir_list, &ir_assign);
    mem_alloc_cnt += type_size;
}

void allocate_ext_dec_list(ParserNode *parserNode) {
    ParserNode *varDec = parserNode->child[0]; // ExtDefList <- VarDec ...
    allocate_var_dec(varDec);
    if (parserNode->child_num == 3) { // DecList <- Dec COMMA DecList
        ParserNode *dec_list = parserNode->child[2];
        allocate_ext_dec_list(dec_list);
    } 
}

// parserNode is a non-terminal exp of an array
int is_last_dimension(ParserNode *parserNode) {
    int current_dim = -1;
    // recursively find terminal ID and its SymbolListNode
    ParserNode *currentNode = parserNode->child[0]; // exp | **exp** ASSIGN exp
    while (strcmp(currentNode->name, "ID")) {
        currentNode = currentNode->child[0]; // exp | **exp** LB exp RB
        current_dim++;
    }
    SymbolListNode *sln = currentNode->symbolListNode;
    return sln->type->array->dim == current_dim + 1;
}

// parserNode is a non-terminal exp of an array: 
IRInstructionList translate_exp_addr(ParserNode* parserNode, int place) { 
    IR_VAR_DEC;
    if (parserNode->child_num == 1) { // if parserNode is Exp -> ID or Exp -> INT
        sln = parserNode->child[0]->symbolListNode;
        sprintf(op1, "s%d", sln->sym_id);
        sprintf(res, "p%d", place);
        ir1 = createInstructionList(createInstruction(IR_OP_ASSIGN, op1, NULL, res));
        return ir1;
    } else if (parserNode->child_num == 4) { // if parserNode is Exp -> Exp LB Exp RB
        ParserNode *array_exp = parserNode->child[0];
        ParserNode *idx_exp = parserNode->child[2];
        t1 = new_place();
        ir1 = translate_exp_addr(array_exp, t1); // get the addr of $1
        int array_step = array_exp->type->array->step;
        t2 = new_place();
        ir2 = translate_exp(idx_exp, t2); // get the idx calculated by $2
        sprintf(op1, "p%d", t2);
        sprintf(op2, "#%d", array_step);
        sprintf(res, "p%d", place);
        ir3 = createInstructionList(createInstruction(IR_OP_MUL, op1, op2, res)); // idx * step
        sprintf(op1, "p%d", t1);
        sprintf(op2, "p%d", place);
        sprintf(res, "p%d", place);
        ir4 = createInstructionList(createInstruction(IR_OP_ADD, op1, op2, res)); // addr + idx * step
        insertInstructionAfter(&ir1, &ir2); insertInstructionAfter(&ir1, &ir3); insertInstructionAfter(&ir1, &ir4);
        return ir1;
    } else if (parserNode->child_num == 3) { // if parserNode is Exp -> Exp DOT ID
        ParserNode *struct_exp = parserNode->child[0];
        ParserNode *id_exp = parserNode->child[2];
        SymbolListNode *id_sln = symbol_table_lookup(struct_exp->type->structure, id_exp->value.string_value);
        t1 = new_place();
        ir1 = translate_exp_addr(struct_exp, t1); // get the addr of $1
        sprintf(op1, "p%d", t1);
        sprintf(op2, "#%d", id_sln->offset);
        sprintf(res, "p%d", place);
        ir2 = createInstructionList(createInstruction(IR_OP_ADD, op1, op2, res)); // addr + offset
        insertInstructionAfter(&ir1, &ir2);
        return ir1;
    }
    return ir_null;
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
            int int_value = parserNode->child[0]->value.int_value;
            sprintf(op1, "#%d", int_value);
            sprintf(res, "p%d", place);
            return createInstructionList(createInstruction(IR_OP_ASSIGN, op1, NULL, res));
            break;
        case EXP_TYPE_ID: // ID
            sln = parserNode->child[0]->symbolListNode;
            if (sln->type->category == ARRAY || sln->type->category == STRUCTURE) { // array type: copy addr to place
                sprintf(op1, "#%d", sln->alloc_addr);
                sprintf(res, "p%d", place);
            }
            else { // primitive type: copy sym_id to place
                sprintf(op1, "s%d", sln->sym_id);
                sprintf(res, "p%d", place);
            }
            return createInstructionList(createInstruction(IR_OP_ASSIGN, op1, NULL, res));
            break;
        case EXP_TYPE_PAREN_EXP: // LP exp RP
            return translate_exp(parserNode->child[1], place);
        case EXP_TYPE_ASSIGN: // exp ASSIGN exp
            if (parserNode->child[0]->value.exp_type == EXP_TYPE_ARRAY || parserNode->child[0]->value.exp_type == EXP_TYPE_STRUCT) {
                tp = new_place();
                ir1 = translate_exp_addr(parserNode->child[0], tp);
                t1 = new_place();
                ir2 = translate_exp(parserNode->child[2], t1);
                sprintf(op1, "p%d", t1);
                sprintf(res, "p%d", tp);
                ir3 = createInstructionList(createInstruction(IR_OP_ASSIGN_ADDR, op1, NULL, res));
                insertInstructionAfter(&ir1, &ir2); insertInstructionAfter(&ir1, &ir3);
                return ir1;
            }
            else {
                t1 = new_place();
                ir1 = translate_exp(parserNode->child[2], t1);
                sprintf(op1, "p%d", t1);
                sln = parserNode->child[0]->child[0]->symbolListNode;
                sprintf(res, "s%d", sln->sym_id);
                ir3 = createInstructionList(createInstruction(IR_OP_ASSIGN, op1, NULL, res));
                insertInstructionAfter(&ir1, &ir2); insertInstructionAfter(&ir1, &ir3);
                return ir1;
            }
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
        case EXP_TYPE_MINUS: // exp1 MINUS exp2
            t1 = new_place();
            t2 = new_place();
            ir1 = translate_exp(parserNode->child[0], t1);
            ir2 = translate_exp(parserNode->child[2], t2);
            sprintf(op1, "p%d", t1);
            sprintf(op2, "p%d", t2);
            sprintf(res, "p%d", place);
            ir3 = createInstructionList(createInstruction(IR_OP_SUB, op1, op2, res));
            insertInstructionAfter(&ir1, &ir2); insertInstructionAfter(&ir1, &ir3);
            return ir1;
            break;
        case EXP_TYPE_MUL: // exp1 MUL exp2
            t1 = new_place();
            t2 = new_place();
            ir1 = translate_exp(parserNode->child[0], t1);
            ir2 = translate_exp(parserNode->child[2], t2);
            sprintf(op1, "p%d", t1);
            sprintf(op2, "p%d", t2);
            sprintf(res, "p%d", place);
            ir3 = createInstructionList(createInstruction(IR_OP_MUL, op1, op2, res));
            insertInstructionAfter(&ir1, &ir2); insertInstructionAfter(&ir1, &ir3);
            return ir1;
            break;
        case EXP_TYPE_DIV: // exp1 DIV exp2
            t1 = new_place();
            t2 = new_place();
            ir1 = translate_exp(parserNode->child[0], t1);
            ir2 = translate_exp(parserNode->child[2], t2);
            sprintf(op1, "p%d", t1);
            sprintf(op2, "p%d", t2);
            sprintf(res, "p%d", place);
            ir3 = createInstructionList(createInstruction(IR_OP_DIV, op1, op2, res));
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
            return ir1;
            break;
        case EXP_TYPE_CALL: // ID LP RP
            sprintf(op1, "%s", parserNode->child[0]->value.string_value);
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
            sprintf(op1, "%s", parserNode->child[0]->value.string_value);
            sprintf(res, "p%d", place);
            ir3 = createInstructionList(createInstruction(IR_OP_CALL, op1, NULL, res));
            insertInstructionAfter(&ir1, &ir3);
            return ir1;
            break;
        case EXP_TYPE_ARRAY: // exp LB exp RB
            if (parserNode->type->category == PRIMITIVE) { // if current_dim is the last dimension
                ir1 = translate_exp_addr(parserNode, place);
                sprintf(op1, "p%d", place);
                sprintf(res, "p%d", place);
                ir2 = createInstructionList(createInstruction(IR_OP_GET_VALUE, op1, NULL, res)); // return the value in addr
                insertInstructionAfter(&ir1, &ir2);
            }
            return ir1;
            break;
        case EXP_TYPE_STRUCT: // exp DOT id
            ir1 = translate_exp_addr(parserNode, place);
            sprintf(op1, "p%d", place);
            sprintf(res, "p%d", place);
            ir2 = createInstructionList(createInstruction(IR_OP_GET_VALUE, op1, NULL, res)); // return the value in addr
            insertInstructionAfter(&ir1, &ir2);
            return ir1;
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
        case EXP_TYPE_COND_NEQ: // exp1 NEQ exp2
            t1 = new_place();
            t2 = new_place();
            ir1 = translate_exp(parserNode->child[0], t1);
            ir2 = translate_exp(parserNode->child[2], t2);
            sprintf(op1, "p%d", t1);
            sprintf(op2, "p%d", t2);
            sprintf(res, "lb%d", lb_false);
            ir3 = createInstructionList(createInstruction(IR_OP_IF_EQ_GOTO, op1, op2, res));
            sprintf(res, "lb%d", lb_true);
            ir4 = createInstructionList(createInstruction(IR_OP_GOTO, NULL, NULL, res));
            insertInstructionAfter(&ir1, &ir2); insertInstructionAfter(&ir1, &ir3); insertInstructionAfter(&ir1, &ir4);
            return ir1;
            break;
        case EXP_TYPE_COND_LT: // exp1 LT exp2
            t1 = new_place();
            t2 = new_place();
            ir1 = translate_exp(parserNode->child[0], t1);
            ir2 = translate_exp(parserNode->child[2], t2);
            sprintf(op1, "p%d", t1);
            sprintf(op2, "p%d", t2);
            sprintf(res, "lb%d", lb_true);
            ir3 = createInstructionList(createInstruction(IR_OP_IF_LT_GOTO, op1, op2, res));
            sprintf(res, "lb%d", lb_false);
            ir4 = createInstructionList(createInstruction(IR_OP_GOTO, NULL, NULL, res));
            insertInstructionAfter(&ir1, &ir2); insertInstructionAfter(&ir1, &ir3); insertInstructionAfter(&ir1, &ir4);
            return ir1;
            break;
        case EXP_TYPE_COND_LEQ: // exp1 LEQ exp2
            t1 = new_place();
            t2 = new_place();
            ir1 = translate_exp(parserNode->child[0], t1);
            ir2 = translate_exp(parserNode->child[2], t2);
            sprintf(op1, "p%d", t1);
            sprintf(op2, "p%d", t2);
            sprintf(res, "lb%d", lb_true);
            ir3 = createInstructionList(createInstruction(IR_OP_IF_LEQ_GOTO, op1, op2, res));
            sprintf(res, "lb%d", lb_false);
            ir4 = createInstructionList(createInstruction(IR_OP_GOTO, NULL, NULL, res));
            insertInstructionAfter(&ir1, &ir2); insertInstructionAfter(&ir1, &ir3); insertInstructionAfter(&ir1, &ir4);
            return ir1;
            break;
        case EXP_TYPE_COND_GT: // exp1 GT exp2
            t1 = new_place();
            t2 = new_place();
            ir1 = translate_exp(parserNode->child[0], t1);
            ir2 = translate_exp(parserNode->child[2], t2);
            sprintf(op1, "p%d", t1);
            sprintf(op2, "p%d", t2);
            sprintf(res, "lb%d", lb_true);
            ir3 = createInstructionList(createInstruction(IR_OP_IF_LEQ_GOTO, op2, op1, res));
            sprintf(res, "lb%d", lb_false);
            ir4 = createInstructionList(createInstruction(IR_OP_GOTO, NULL, NULL, res));
            insertInstructionAfter(&ir1, &ir2); insertInstructionAfter(&ir1, &ir3); insertInstructionAfter(&ir1, &ir4);
            return ir1;
            break;
        case EXP_TYPE_COND_GEQ: // exp1 GE exp2
            t1 = new_place();
            t2 = new_place();
            ir1 = translate_exp(parserNode->child[0], t1);
            ir2 = translate_exp(parserNode->child[2], t2);
            sprintf(op1, "p%d", t1);
            sprintf(op2, "p%d", t2);
            sprintf(res, "lb%d", lb_true);
            ir3 = createInstructionList(createInstruction(IR_OP_IF_LT_GOTO, op2, op1, res));
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
            ir2 = createInstructionList(createInstruction(IR_OP_RETURN, NULL, NULL, res));
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
        case STMT_TYPE_COMPST: // compst
            return translate_comp_st(parserNode->child[0]);
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
            if (parserNode->child[0]->type->category == ARRAY || parserNode->child[0]->type->category == STRUCTURE) {
                ir1 = translate_exp_addr(parserNode->child[0], tp);
            } else {
                ir1 = translate_exp(parserNode->child[0], tp);
            }
            args_list[(*args_cnt)++] = tp;
            return ir1;
            break;
        case ARGS_TYPE_ARGS: // exp COMMA args
            tp = new_place();
            if (parserNode->child[0]->value.exp_type == EXP_TYPE_ARRAY || parserNode->child[0]->value.exp_type == EXP_TYPE_STRUCT) {
                ir1 = translate_exp_addr(parserNode->child[0], tp);
            } else {
                ir1 = translate_exp(parserNode->child[0], tp);
            }
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

IRInstructionList translate_dec_list(ParserNode *parserNode) {
    IR_VAR_DEC;
    ParserNode *dec = parserNode->child[0];
    if (dec->child_num == 3) { // Dec <- VarDec assign exp
        sln = dec->child[0]->child[0]->symbolListNode; // VarDec <- ID
        tp = new_place();
        ir1 = translate_exp(dec->child[2], tp);
        sprintf(op1, "p%d", tp);
        sprintf(res, "s%d", sln->sym_id);
        ir2 = createInstructionList(createInstruction(IR_OP_ASSIGN, op1, NULL, res));
        insertInstructionAfter(&ir1, &ir2);
    }
    if (parserNode->child_num == 3) { // DecList <- Dec COMMA DecList
        ParserNode *dec_list = parserNode->child[2];
        ir3 = translate_dec_list(dec_list);
        insertInstructionAfter(&ir1, &ir3);
    } 
    return ir1;
}

IRInstructionList translate_def_list(ParserNode *parserNode) {
    IR_VAR_DEC;
    if (parserNode == NULL) {
        printf("in translate_def_list, parserNode is NULL\n");
        return ir_null;
    }
    if (parserNode->empty_value) {
        return ir_null;
    }
    ParserNode *def = parserNode->child[0]; // DefList <- Def DefList
    ParserNode *def_list = parserNode->child[1]; // Def <- Specifier DecList SEMI
    ParserNode *dec_list = def->child[1]; // Def <- Specifier DecList SEMI
    ir1 = translate_dec_list(dec_list);
    ir2 = translate_def_list(def_list);
    insertInstructionAfter(&ir1, &ir2);
    return ir1;
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
    ParserNode *def_list = parserNode->child[1];
    ParserNode *stmt_list = parserNode->child[2];
    ir1 = translate_def_list(def_list);
    ir2 = translate_stmt_list(stmt_list);
    insertInstructionAfter(&ir1, &ir2);
    return ir1;
}

IRInstructionList translate_var_list(ParserNode *parserNode) {
    IR_VAR_DEC;
    if (parserNode == NULL) {
        printf("in translate_var_list, parserNode is NULL\n");
        return ir_null;
    }
    ParserNode *paramDec = parserNode->child[0];
    ParserNode *varDec = paramDec->child[1];
    if (varDec->child_num == 1) { // VarDec <- ID
        sln = varDec->child[0]->symbolListNode; 
        sprintf(res, "s%d", sln->sym_id); 
    } else {
        ParserNode *currentVarDec = varDec;
        while (currentVarDec->child_num == 4) { // VarDec <- VarDec LB INT RB
            currentVarDec = currentVarDec->child[0];
        }
        sln = currentVarDec->child[0]->symbolListNode; 
    }
    sprintf(res, "s%d", sln->sym_id); 
    ir1 = createInstructionList(createInstruction(IR_OP_PARAM, NULL, NULL, res));
    if (parserNode->child_num == 3) { // Varlist <- ParamDec COMMA Varlist
        ParserNode *varList = parserNode->child[2];
        ir2 = translate_var_list(varList);
        insertInstructionAfter(&ir1, &ir2);
    } 
    return ir1;
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
        ir3 = translate_ext_def_list(ext_def_list);
        return ir3;
    } else if (ext_def->value.exp_def_type == EXP_DEF_TYPE_FUNDEC) { // ExtDef <- FunDef CompSt
        ParserNode* funDef = ext_def->child[0];
        ParserNode* funDec = funDef->child[1]; // FunDef <- Specifier FunDec
        sprintf(res, "%s", funDec->child[0]->value.string_value); // FunDec <- ID LP RP
        ir1 = createInstructionList(createInstruction(IR_OP_FUNC, NULL, NULL, res)); 
        if (!strcmp(res, "main")) {
            sprintf(res, "#%d", MEM_ALLOC_START);
            sprintf(op1, "%d", mem_alloc_cnt - MEM_ALLOC_START);
            IRInstructionList ir_alloc = createInstructionList(createInstruction(IR_OP_DEC, op1, NULL, res));
            insertInstructionAfter(&alloc_ir_list, &ir_alloc);
            insertInstructionAfter(&ir1, &alloc_ir_list);
        }
        if (funDec->child_num == 4) { // FunDec <- ID LP Varlist RP
            ParserNode* varList = funDec->child[2];
            ir4 = translate_var_list(varList);
            insertInstructionAfter(&ir1, &ir4);
        } 
        ir2 = translate_comp_st(ext_def->child[1]);
        ir3 = translate_ext_def_list(ext_def_list);
        insertInstructionAfter(&ir1, &ir2); insertInstructionAfter(&ir1, &ir3);
        return ir1;
    } else {
        printf("in translate_extdef_list, extdef->value.expdef_type error\n");
        return ir_null;
    }
    printf("translate ext def list error\n");
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
    return ir1;
}

