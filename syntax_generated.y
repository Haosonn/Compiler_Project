%{
    #include <stdio.h>
    #include <stdlib.h>
    #include <string.h>
    #include <stdarg.h>
    #include "lex.yy.c"
    #include "parser_node.h"
    #include "symbol_table.h"
    #include "ir.h"
    #include "ir_translate.h"
    // #define YY_USER_ACTION \
    //     yylloc.first_line = yylineno; \
    //     yylloc.first_column = yycolno; \
    //     yylloc.last_line = yylineno; \
    //     yylloc.last_column = yycolno + yyleng; \
    //     yycolno += yyleng;
    // yydebug = 1;

    char *source_path; 
    struct ParserNode * rootNode = NULL; 
    IRInstructionList alloc_ir_list = {NULL, NULL};
    int lexeme_error = 0;
    int syntax_error = 0;
    // phase 2
    char *semantic_error_msg[] = {
        "a variable is used without a definition",
        "a function is used without a definition",
        "a variable is redefined in the same scope",
        "a function is redefined",
        "unmatching types appear at both sides of the assignment operator",
        "rvalue appears on the left-hand side of the assignment operator",
        "unmatching operands",
        "a function's return value type mismatches the declared type",
        "a function's arguments mismatch the declared parameters",
        "applying indexing operator on non-array type variables",
        "applying function invocation operator on non-function names",
        "array indexing with a non-integer type expression",
        "accessing members of a non-structure variable",
        "accessing an undefined structure member",
        "redefine the same structure type"};



    void yyerror(const char*);

    void printSyntaxError(char *s, const int lineno) {
        syntax_error = 1;
        printf("Error type B at Line %d: %s\n", lineno, s);
    }

    void printSemanticError(int typeId , const int lineno) {
        printf("Error type %d at Line %d: %s\n",typeId,lineno,semantic_error_msg[typeId - 1]);
    }

    void addParserDerivation(struct ParserNode *node, ...) {
        va_list args;
        va_start(args, node);
        while(1) {
            struct ParserNode *child = va_arg(args, struct ParserNode*);
           if(child == NULL) break;
            addParserNode(node, child);
        }
        va_end(args);
    }

    int typeNotMatch(struct ParserNode *node1,struct ParserNode *node2)
    {
        return !type_equal(node1->type, node2->type)&&node1->type!=NULL&&node2->type!=NULL;
    }    

    void printParserTree() {
#ifndef PRINT_PARSER_TREE
        return;
#endif
        if(lexeme_error || syntax_error)
            return;
        printParserNode(rootNode, 0);
    }

    void printDerivation(char* der) {

#ifndef PRINT_DERIVATION
            return;
#endif

        printf("%s\n", der);
    }

%}



%union {
    int int_value;
    float float_value;
    char *string_value;
    struct ParserNode *parser_node;
}

%token <parser_node> INT FLOAT CHAR
%token <parser_node> TYPE IDT ASSIGN SEMI LITERAL COMMA IF ELSE WHILE FOR RETURN PLUS MINUS MUL DIV EQ NEQ LT GT LEQ GEQ LP RP LB RB LCT RCT AND OR NOT STRUCT DOT READ WRITE

%right ASSIGN
%left OR
%left AND
%left LT GT LEQ GEQ EQ NEQ
%left PLUS MINUS
%left MUL DIV
%right NOT
%left LP RP LB RB LCT RCT DOT
%nonassoc IF error
%nonassoc ELSE

%type <parser_node> Program ExtDefList ExtDef ExtDecList Specifier StructSpecifier VarDec FunDec VarList ParamDec CompSt StmtList Stmt DefList Def DecList Dec Exp Args LC RC ID LPF RPF
/* %type <parser_node> Program ExtDefList ExtDef ExtDecList Specifier StructSpecifier VarDec FunDec VarList ParamDec CompSt StmtList Stmt DefList Def DefMS DecList Dec Exp Args */

%%
Program: ExtDefList { printDerivation("Program -> ExtDefList\n"); $$ = initParserNode("Program", yylineno); addParserDerivation($$, $1, NULL); cal_line($$); rootNode = $$;
    #ifdef PRINT_SYMBOL_TABLE
        printf("var table:\n");
        symbol_table_print(global_table);
        printf("\n");
        printf("function table:\n");
        symbol_table_print(function_table);
        printf("\n");
        printf("structure table:\n");
        symbol_table_print(structure_table);
        printf("\n");
    #endif
    }
    ;

ExtDefList: ExtDef ExtDefList { printDerivation("ExtDefList -> ExtDef ExtDefList\n"); $$ = initParserNode("ExtDefList", yylineno); addParserDerivation($$, $1, $2, NULL); cal_line($$); }
    | { printDerivation("ExtDefList -> empty\n"); $$ = initParserNode("ExtDefList", yylineno); $$->empty_value = 1;  }
    ;

ExtDef: Specifier ExtDecList SEMI { printDerivation("ExtDef -> Specifier ExtDecList SEMI\n"); $$ = initParserNode("ExtDef", yylineno); addParserDerivation($$, $1, $2, $3, NULL); cal_line($$);
        $$->value.exp_def_type = EXP_DEF_TYPE_VARDEC;
        passType($2, $1->type);  
    }
    | Specifier SEMI { printDerivation("ExtDef -> Specifier SEMI\n"); $$ = initParserNode("ExtDef", yylineno); addParserDerivation($$, $1, $2, NULL); cal_line($$); }
    | Specifier FunDec CompSt { printDerivation("ExtDef -> Specifier FunDec CompSt\n"); $$ = initParserNode("ExtDef", yylineno); addParserDerivation($$, $1, $2, $3, NULL); cal_line($$);
        temp_member_table = scope_list_pop(scope_stack);
        symbol_table_remove_empty(global_table);
        memcpy($2->type->function,temp_member_table,sizeof(SymbolTable));
        symbol_table_insert($2->type->function,"return_type",$1->type);
        if(check_return_type($3, $1->type)){
            printSemanticError(8, $2->line);
        }
        $$->value.exp_def_type = EXP_DEF_TYPE_FUNDEC;
    }
    | ExtDecList SEMI { printDerivation("ExtDef -> ExtDecList SEMI\n"); printSyntaxError("Missing specifier", $1->line);}
    | Specifier error { printDerivation("ExtDef -> Specifier error\n"); printSyntaxError("Missing semicolon ';'", $1->line);}
    | Specifier ExtDecList error { printDerivation("ExtDef -> Specifier ExtDecList error\n"); printSyntaxError("Missing semicolon ';'", $2->line);}
    ;

ExtDecList: VarDec { printDerivation("ExtDecList -> VarDec\n"); $$ = initParserNode("ExtDecList", yylineno); addParserDerivation($$, $1, NULL); cal_line($$); 
        if($1->type->category == ARRAY){
            Array *array = $1->type->array;
            while(array->base!=NULL && array->base->category == ARRAY){
                array = array->base->array;
            }
            Type *type = (Type *)malloc(sizeof(Type));
            array->base = type;
            $1->type = type;
        }
    }
    | VarDec COMMA ExtDecList { printDerivation("ExtDecList -> VarDec COMMA ExtDecList\n"); $$ = initParserNode("ExtDecList", yylineno); addParserDerivation($$, $1, $2, $3, NULL); cal_line($$);
        if($1->type->category == ARRAY){
            Array *array = $1->type->array;
            while(array->base!=NULL && array->base->category == ARRAY){
                array = array->base->array;
            }
            Type *type = (Type *)malloc(sizeof(Type));
            array->base = type;
            $1->type = type;
        }
    }
    ;

Specifier: TYPE { printDerivation("Specifier -> TYPE\n"); $$ = initParserNode("Specifier", yylineno); addParserDerivation($$, $1, NULL); cal_line($$);
        $$->type = $1->type;
    }
    | StructSpecifier { printDerivation("Specifier -> StructSpecifier\n"); $$ = initParserNode("Specifier", yylineno); addParserDerivation($$, $1, NULL); cal_line($$);
        $$->type = $1->type;
    }
    ;

StructSpecifier: STRUCT IDT LC DefList RC { printDerivation("StructSpecifier -> STRUCT ID LC DefList RC\n"); $$ = initParserNode("StructSpecifier", yylineno); addParserDerivation($$, $1, $2, $3, $4, $5, NULL); cal_line($$);
        Type *type = (Type *)malloc(sizeof(Type));
        type->category = STRUCTURE;
        type->structure = temp_member_table;
        $$->type = type;
        if(var_declare(structure_table, structure_stack, $2->value.string_value, type)){
            printSemanticError(15, $2->line);
        }
    }
    | STRUCT IDT LC DefList error { printDerivation("StructSpecifier -> STRUCT ID LC DefList error\n"); printSyntaxError("Missing closing bracket '}'", (int)$4->line); }
    | STRUCT IDT { printDerivation("StructSpecifier -> STRUCT ID\n"); $$ = initParserNode("StructSpecifier", yylineno); addParserDerivation($$, $1, $2, NULL); cal_line($$);
        SymbolListNode* sln = symbol_table_lookup(structure_table, $2->value.string_value);
        $$->type = sln->type;
    }
    ;

VarDec: ID { printDerivation("VarDec -> ID\n"); $$ = initParserNode("VarDec", yylineno); addParserDerivation($$, $1, NULL); cal_line($$);
        $1->type = (Type *)malloc(sizeof(Type));
        $1->type->category = PRIMITIVE;
        if(var_declare(global_table, scope_stack, $1->value.string_value,$1->type)){
            printSemanticError(3, $1->line);
        }
        $$->type = $1->type;
    }
    | VarDec LB INT RB { printDerivation("VarDec -> VarDec LB INT RB\n"); $$ = initParserNode("VarDec", yylineno); addParserDerivation($$, $1, $2, $3, $4, NULL); cal_line($$);
        if($1->type->category != ARRAY) {
            Type *type = (Type *)malloc(sizeof(Type));
            type->category = ARRAY;
            type->array=(Array *)malloc(sizeof(Array));
            type->array->size = $3->value.int_value;
            type->array->base = NULL;
            memcpy($1->type, type, sizeof(Type));
            $1->value.int_value = mem_alloc_cnt;
            //todo: add alloc_addr in SymbolListNode
            int array_len = $3->value.int_value;
            char res[OP_LEN_MAX], op1[OP_LEN_MAX];
            sprintf(res, "%x", mem_alloc_cnt);
            sprintf(op1, "%d", array_len);
            IRInstructionList ir_alloc = createInstructionList(createInstruction(IR_OP_DEC, op1, NULL, res));
            insertInstructionAfter(&alloc_ir_list, &ir_alloc);
            mem_alloc_cnt += array_len >> 2;
        }
        else {
            Type *type = (Type *)malloc(sizeof(Type));
            type->category = ARRAY;
            type->array=(Array *)malloc(sizeof(Array));
            type->array->size = $3->value.int_value;
            type->array->base = NULL;
            Array *array = $1->type->array;
            while(array->base!=NULL && array->base->category == ARRAY){
                array = array->base->array;
            }
            array->base = type;
        }
        $$->type = $1->type;
    }
    | VarDec LB INT error { printDerivation("VarDec -> VarDec LB INT error\n"); printSyntaxError("Missing closing brace ']'", (int)$3->line); }
    ;

FunDec: IDT LPF VarList RPF { printDerivation("FunDec -> ID LP VarList RP\n"); $$ = initParserNode("FunDec", yylineno); addParserDerivation($$, $1, $2, $3, $4, NULL); cal_line($$);
        Type *type = (Type *)malloc(sizeof(Type));
        type->category = FUNCTION;
        type->function =symbol_table_init(); 
        $$->type = type;

        if(function_declare(function_table, $1->value.string_value, type)){
            printSemanticError(4, $1->line);
        }
    }
    | IDT LPF RPF { printDerivation("FunDec -> ID LP RP\n"); $$ = initParserNode("FunDec", yylineno); addParserDerivation($$, $1, $2, $3, NULL); cal_line($$);
        Type *type = (Type *)malloc(sizeof(Type));
        type->category = FUNCTION;
        type->function = symbol_table_init();
        // Type *return_type = (Type *)malloc(sizeof(Type));
        // symbol_table_insert(type->function, $1->value.string_value, return_type); 
        $$->type = type;

        if(function_declare(function_table, $1->value.string_value, type)){
            printSemanticError(4, $1->line);
        }
        // temp_member_table = symbol_table_init();
    }
    | IDT LP error { printDerivation("FunDec -> ID LP error\n"); printSyntaxError("Missing closing parenthesis ')'",$2->line); }
    ;

VarList: ParamDec COMMA VarList { printDerivation("VarList -> ParamDec COMMA VarList\n"); $$ = initParserNode("VarList", yylineno); addParserDerivation($$, $1, $2, $3, NULL); cal_line($$); }
    | ParamDec { printDerivation("VarList -> ParamDec\n"); $$ = initParserNode("VarList", yylineno); addParserDerivation($$, $1, NULL); cal_line($$); }
    ;

ParamDec: Specifier VarDec { printDerivation("ParamDec -> Specifier VarDec\n"); $$ = initParserNode("ParamDec", yylineno); addParserDerivation($$, $1, $2, NULL); cal_line($$);
    memcpy($2->type, $1->type, sizeof(Type));
    }
    ;

CompSt: LC DefList StmtList RC { printDerivation("CompSt -> LC DefList StmtList RC\n"); $$ = initParserNode("CompSt", yylineno); addParserDerivation($$, $1, $2, $3, $4, NULL); cal_line($$); 
    }
    | LC DefList StmtList error { printDerivation("CompSt -> LC DefList StmtList error\n"); printSyntaxError("Missing closing bracket '}'", (int)$3->line); }
    ;

StmtList: Stmt StmtList { printDerivation("StmtList -> Stmt StmtList\n"); $$ = initParserNode("StmtList", yylineno); addParserDerivation($$, $1, $2, NULL); cal_line($$); 
    }
    | Stmt Def StmtList { printDerivation("StmtList -> Stmt Def StmtList\n"); printSyntaxError("Missing specifier", $$->line);}
    | Stmt Def Def StmtList { printDerivation("StmtList -> Stmt Def StmtList\n"); printSyntaxError("Missing specifier", $$->line);}
    | Stmt Def Def Def StmtList { printDerivation("StmtList -> Stmt Def StmtList\n"); printSyntaxError("Missing specifier", $$->line);}
    | Stmt Def Def Def Def StmtList { printDerivation("StmtList -> Stmt Def StmtList\n"); printSyntaxError("Missing specifier", $$->line);}
    | { printDerivation("StmtList -> empty\n"); $$ = initParserNode("StmtList", yylineno); $$->empty_value = 1;  }
;

Stmt: Exp SEMI { printDerivation("Stmt -> Exp SEMI\n"); $$ = initParserNode("Stmt", yylineno); addParserDerivation($$, $1, $2, NULL); cal_line($$); 
        $$->value.stmt_type = STMT_TYPE_EXP;
    }
    | CompSt { printDerivation("Stmt -> CompSt\n"); $$ = initParserNode("Stmt", yylineno); addParserDerivation($$, $1, NULL); cal_line($$); 
        $$->value.stmt_type = STMT_TYPE_COMPST;
    }
    | RETURN Exp SEMI { printDerivation("Stmt -> RETURN Exp SEMI\n"); $$ = initParserNode("Stmt", yylineno); addParserDerivation($$, $1, $2, $3, NULL); cal_line($$); 
        $$->value.stmt_type = STMT_TYPE_RETURN;
    }
    | IF LP Exp RP Stmt { printDerivation("Stmt -> IF LP Exp RP Stmt\n"); $$ = initParserNode("Stmt", yylineno); addParserDerivation($$, $1, $2, $3, $4, $5, NULL); cal_line($$); 
        $$->value.stmt_type = STMT_TYPE_IF;
    }
    | IF LP Exp RP Stmt ELSE Stmt { printDerivation("Stmt -> IF LP Exp RP Stmt ELSE Stmt\n"); $$ = initParserNode("Stmt", yylineno); addParserDerivation($$, $1, $2, $3, $4, $5, $6, $7, NULL); cal_line($$); 
        $$->value.stmt_type = STMT_TYPE_IF_ELSE;
    }
    | WHILE LP Exp RP Stmt { printDerivation("Stmt -> WHILE LP Exp RP Stmt\n"); $$ = initParserNode("Stmt", yylineno); addParserDerivation($$, $1, $2, $3, $4, $5, NULL); cal_line($$); 
        $$->value.stmt_type = STMT_TYPE_WHILE;
    }
    | FOR LP Exp SEMI Exp SEMI Exp RP Stmt { printDerivation("Stmt -> FOR LP Exp SEMI Exp SEMI Exp RP Semt\n"); $$ = initParserNode("Stmt", yylineno); addParserDerivation($$, $1, $2, $3, $4, $5, $6, $7, $8, $9, NULL); cal_line($$); }
    | FOR LP Def Exp SEMI Exp RP Stmt { printDerivation("Stmt -> FOR LP Def Exp SEMI Exp RP Stmt\n"); $$ = initParserNode("Stmt", yylineno); addParserDerivation($$, $1, $2, $3, $4, $5, $6, $7, $8, NULL); cal_line($$); }
    | ELSE Stmt { printDerivation("Stmt -> ELSE Stmt\n"); $$ = initParserNode("Stmt", yylineno); printSyntaxError("Lack IF for ELSE", (int)$1->line); }
    | Exp error { printDerivation("Stmt -> Exp error\n"); printSyntaxError("Missing semicolon ';'", $1->line);}
    | RETURN Exp error { printDerivation("Stmt -> RETURN Exp error\n"); printSyntaxError("Missing semicolon ';'", $2->line);}
    | IF LP error { printDerivation("Stmt -> IF LP error\n"); printSyntaxError("Missing closing parenthesis ')'", (int)$2->line); }
    | IF error Exp RP Stmt { printDerivation("Stmt -> IF error Exp RP Stmt\n"); printSyntaxError("Missing start parenthesis '('", (int)$3->line); }
    | IF error Exp RP Stmt ELSE Stmt { printDerivation("Stmt -> IF error Exp RP Stmt ELSE Stmt\n"); printSyntaxError("Missing start parenthesis '('", (int)$3->line); }
    | WHILE LP error {printDerivation("Stmt -> WHILE LP error\n"); printSyntaxError("Missing closing parenthesis ')'", (int)$2->line);}
    | WHILE error Exp RP Stmt { printDerivation("Stmt -> WHILE error Exp RP Stmt\n"); printSyntaxError("Missing start parenthesis '('", (int)$3->line); }
    | FOR LP error { printDerivation("Stmt -> FOR LP error\n"); printSyntaxError("Missing closing parenthesis ')'", (int)$2->line); }
    ;

DefList: Def DefList { printDerivation("DefList -> Def DefList\n"); $$ = initParserNode("DefList", yylineno); addParserDerivation($$, $1, $2, NULL); cal_line($$); }
    | { printDerivation("DefList -> empty\n"); $$ = initParserNode("DefList", yylineno); $$->empty_value = 1;  }
    ;

Def: Specifier DecList SEMI { printDerivation("Def -> Specifier DecList SEMI\n"); $$ = initParserNode("Def", yylineno); addParserDerivation($$, $1, $2, $3, NULL); cal_line($$);
        // if ($1->type==NULL){
            // undefined structure
        // } 
        passType($2, $1->type); 
        if(check_dec_assign_type($2, $1->type)){
            printSemanticError(5, $2->line);
        }
    }
    | Specifier DecList error { printDerivation("Def -> Specifier DecList error\n"); printSyntaxError("Missing semicolon ';'", $2->line);}
    ;

DecList: Dec { printDerivation("DecList -> Dec\n"); $$ = initParserNode("DecList", yylineno); addParserDerivation($$, $1, NULL); cal_line($$);
        if($1->type->category == ARRAY){
            Array *array = $1->type->array;
            while(array->base!=NULL && array->base->category == ARRAY){
                array = array->base->array;
            }
            Type *type = (Type *)malloc(sizeof(Type));
            array->base = type;
            $1->type = type;
        }
    }        
    | Dec COMMA DecList { printDerivation("DecList -> Dec COMMA DecList\n"); $$ = initParserNode("DecList", yylineno); addParserDerivation($$, $1, $2, $3, NULL); cal_line($$);
           if($1->type->category == ARRAY){
            Array *array = $1->type->array;
            while(array->base!=NULL && array->base->category == ARRAY){
                array = array->base->array;
            }
            Type *type = (Type *)malloc(sizeof(Type));
            array->base = type;
            $1->type = type;
        }
    }
    ;

Dec: VarDec { printDerivation("Dec -> VarDec\n"); $$ = initParserNode("Dec", yylineno); addParserDerivation($$, $1, NULL); cal_line($$); }
    | VarDec ASSIGN Exp { printDerivation("Dec -> VarDec ASSIGN Exp\n"); $$ = initParserNode("Dec", yylineno); addParserDerivation($$, $1, $2, $3, NULL); cal_line($$); }
    ;

Exp: Exp ASSIGN Exp { printDerivation("Exp -> Exp ASSIGN Exp\n"); $$ = initParserNode("Exp", yylineno); addParserDerivation($$, $1, $2, $3, NULL); cal_line($$);
        if(typeNotMatch($1, $3)) 
            printSemanticError(5, $1->line); 
        if(!$1->is_left_value)
            printSemanticError(6, $1->line);
        $$->value.exp_type = EXP_TYPE_ASSIGN;
    }
    | Exp OR Exp { printDerivation("Exp -> Exp OR Exp\n"); $$ = initParserNode("Exp", yylineno); addParserDerivation($$, $1, $2, $3, NULL); cal_line($$); 
        if(typeNotMatch($1, $3)) printSemanticError(7, $1->line); 
        $$->value.exp_type = EXP_TYPE_COND_OR;
    }
    | Exp AND Exp { printDerivation("Exp -> Exp AND Exp\n"); $$ = initParserNode("Exp", yylineno); addParserDerivation($$, $1, $2, $3, NULL); cal_line($$); 
        if(typeNotMatch($1, $3)) printSemanticError(7, $1->line); 
        $$->value.exp_type = EXP_TYPE_COND_AND;
    }
    | Exp EQ Exp { printDerivation("Exp -> Exp EQ Exp\n"); $$ = initParserNode("Exp", yylineno); addParserDerivation($$, $1, $2, $3, NULL); cal_line($$); 
        if(typeNotMatch($1, $3)) printSemanticError(7, $1->line); 
        $$->value.exp_type = EXP_TYPE_COND_EQ;
    }
    | Exp NEQ Exp { printDerivation("Exp -> Exp NEQ Exp\n"); $$ = initParserNode("Exp", yylineno); addParserDerivation($$, $1, $2, $3, NULL); cal_line($$); 
        if(typeNotMatch($1, $3)) printSemanticError(7, $1->line); 
        $$->value.exp_type = EXP_TYPE_COND_NEQ;
    }
    | Exp LT Exp { printDerivation("Exp -> Exp LT Exp\n"); $$ = initParserNode("Exp", yylineno); addParserDerivation($$, $1, $2, $3, NULL); cal_line($$);
        if(typeNotMatch($1, $3)) printSemanticError(7, $1->line); 
        $$->value.exp_type = EXP_TYPE_COND_LT;
    }
    | Exp GT Exp { printDerivation("Exp -> Exp GT Exp\n"); $$ = initParserNode("Exp", yylineno); addParserDerivation($$, $1, $2, $3, NULL); cal_line($$);
        if(typeNotMatch($1, $3)) printSemanticError(7, $1->line); 
        $$->value.exp_type = EXP_TYPE_COND_GT;
    }
    | Exp LEQ Exp { printDerivation("Exp -> Exp LEQ Exp\n"); $$ = initParserNode("Exp", yylineno); addParserDerivation($$, $1, $2, $3, NULL); cal_line($$);
        if(typeNotMatch($1, $3)) printSemanticError(7, $1->line);
        $$->value.exp_type = EXP_TYPE_COND_LEQ;
    }
    | Exp GEQ Exp { printDerivation("Exp -> Exp GEQ Exp\n"); $$ = initParserNode("Exp", yylineno); addParserDerivation($$, $1, $2, $3, NULL); cal_line($$);
        if(typeNotMatch($1, $3)) printSemanticError(7, $1->line); 
        $$->value.exp_type = EXP_TYPE_COND_GEQ;
    }
    | Exp PLUS Exp { printDerivation("Exp -> Exp PLUS Exp\n"); $$ = initParserNode("Exp", yylineno); addParserDerivation($$, $1, $2, $3, NULL); cal_line($$);
        if(typeNotMatch($1, $3)) printSemanticError(7, $1->line); 
        $$->value.exp_type = EXP_TYPE_PLUS;
    }
    | Exp MINUS Exp { printDerivation("Exp -> Exp MINUS Exp\n"); $$ = initParserNode("Exp", yylineno); addParserDerivation($$, $1, $2, $3, NULL); cal_line($$);
        if(typeNotMatch($1, $3)) printSemanticError(7, $1->line);
        $$->value.exp_type = EXP_TYPE_MINUS;
    }
    | Exp MUL Exp { printDerivation("Exp -> Exp MUL Exp\n"); $$ = initParserNode("Exp", yylineno); addParserDerivation($$, $1, $2, $3, NULL); cal_line($$);
        if(typeNotMatch($1, $3)) printSemanticError(7, $1->line);
        $$->value.exp_type = EXP_TYPE_MUL;
    }
    | Exp DIV Exp { printDerivation("Exp -> Exp DIV Exp\n"); $$ = initParserNode("Exp", yylineno); addParserDerivation($$, $1, $2, $3, NULL); cal_line($$);
        if(typeNotMatch($1, $3)) printSemanticError(7, $1->line);
        $$->value.exp_type = EXP_TYPE_DIV;
    }
    | LP Exp RP { printDerivation("Exp -> LP Exp RP\n"); $$ = initParserNode("Exp", yylineno); addParserDerivation($$, $1, $2, $3, NULL); cal_line($$); }
    // | MINUS Exp %prec UMINUS 
    | PLUS Exp { printDerivation("Exp -> PLUS Exp\n"); $$ = initParserNode("Exp", yylineno); addParserDerivation($$, $1, $2, NULL); cal_line($$); }
    | MINUS Exp { printDerivation("Exp -> MINUS Exp\n"); $$ = initParserNode("Exp", yylineno); addParserDerivation($$, $1, $2, NULL); cal_line($$); 
        $$->value.exp_type = EXP_TYPE_UMINUS;
    }
    | NOT Exp { printDerivation("Exp -> NOT Exp\n"); $$ = initParserNode("Exp", yylineno); addParserDerivation($$, $1, $2, NULL); cal_line($$); 
        $$->value.exp_type = EXP_TYPE_COND_NOT;
    }
    | WRITE LP Exp RP {
        printDerivation("Exp -> WRITE LP Exp RP\n"); $$ = initParserNode("Exp", yylineno); addParserDerivation($$, $1, $2, $3, $4, NULL); cal_line($$);
        $$->value.exp_type = EXP_TYPE_WRITE;
    }
    | ID LP Args RP { printDerivation("Exp -> ID LP Args RP\n"); $$ = initParserNode("Exp", yylineno); addParserDerivation($$, $1, $2, $3, $4, NULL); cal_line($$); 
        SymbolListNode *sln = symbol_table_lookup(function_table, $1->value.string_value);
        if(sln == NULL || sln->type == NULL){
            printSemanticError(2, $1->line);
            $$->type = NULL;
        }
        else if(sln->type->category != FUNCTION){
            // not used
            printSemanticError(11, $1->line);
            $$->type = NULL;
        }
        else{
            if(check_function_args(sln->type->function, temp_member_table)){
                printSemanticError(9, $1->line);
            }
            temp_member_table = NULL;
            $$->type = sln->type->function->head->list->head->type;
            $$->value.exp_type = EXP_TYPE_CALL_ARGS;
        }
    }
    | READ LP RP { printDerivation("Exp -> READ LP RP\n"); $$ = initParserNode("Exp", yylineno); addParserDerivation($$, $1, $2, $3, NULL); cal_line($$); 
        $$->value.exp_type = EXP_TYPE_READ; 
    }
    | ID LP RP { printDerivation("Exp -> ID LP RP\n"); $$ = initParserNode("Exp", yylineno); addParserDerivation($$, $1, $2, $3, NULL); cal_line($$); 
        SymbolListNode *sln = symbol_table_lookup(function_table, $1->value.string_value);
        if(sln->type == NULL){
            printSemanticError(2, $1->line);
            $$->type = NULL;
        }
        else if(sln->type->category != FUNCTION){
            // not used
            printSemanticError(11, $1->line);
            $$->type = NULL;
        }else{
            if(check_function_args(sln->type->function, NULL)){
                printSemanticError(9, $1->line);
            }
            $$->type = sln->type->function->head->list->head->type;
            $$->value.exp_type = EXP_TYPE_CALL;
        }
    }
    | Exp LB Exp RB { printDerivation("Exp -> Exp LB Exp RB\n"); $$ = initParserNode("Exp", yylineno); addParserDerivation($$, $1, $2, $3, $4, NULL); cal_line($$); $$->is_left_value = 1; 
        if($1->type==NULL || $1->type->category != ARRAY){
            printSemanticError(10, $1->line);
            $$->type = NULL;
        }else{
            if($3->type->category != PRIMITIVE || $3->type->primitive != SEMANTIC_TYPE_INT){
                printSemanticError(12, $3->line);
            }else{
                $$->type = $1->type->array->base;
                $$->value.exp_type = EXP_TYPE_ARRAY;
            }
        }
    }
    | Exp DOT ID { printDerivation("Exp -> Exp DOT ID\n"); $$ = initParserNode("Exp", yylineno); addParserDerivation($$, $1, $2, $3, NULL); cal_line($$); $$->is_left_value = 1; 
        if($1->type->category != STRUCTURE){
            printSemanticError(13, $1->line);
            $$->type = NULL;
        }else{
            SymbolListNode *sln = symbol_table_lookup($1->type->structure, $3->value.string_value);
            if(sln->type == NULL){
                printSemanticError(14, $3->line);
            }
            $$->type = sln->type;
            $$->value.exp_type = EXP_TYPE_STRUCT;
            // $$->ir_list = translate_exp($$);
        }
    }
    | ID { printDerivation("Exp -> ID\n"); $$ = initParserNode("Exp", yylineno); addParserDerivation($$, $1, NULL); cal_line($$); $$->is_left_value = 1; 
        SymbolListNode* sln = symbol_table_lookup(global_table, $1->value.string_value);
        if(sln->type == NULL){
            printSemanticError(1, $1->line);
        }
        $$->type = sln->type;
        $1->symbolListNode=sln;
        $$->value.exp_type = EXP_TYPE_ID;
        // $$->ir_list = translate_exp($$);
    }
    | INT { printDerivation("Exp -> INT\n"); $$ = initParserNode("Exp", yylineno); addParserDerivation($$, $1, NULL); cal_line($$); 
        $$->value.exp_type = EXP_TYPE_INT; 
        // $$->ir_list = translate_exp($$);
    }
    | FLOAT { printDerivation("Exp -> FLOAT\n"); $$ = initParserNode("Exp", yylineno); addParserDerivation($$, $1, NULL); cal_line($$); }
    | CHAR { printDerivation("Exp -> CHAR\n"); $$ = initParserNode("Exp", yylineno); addParserDerivation($$, $1, NULL); cal_line($$); }
    | LITERAL { printDerivation("Exp -> LITERAL\n"); $$ = initParserNode("Exp", yylineno); addParserDerivation($$, $1, NULL); cal_line($$); }
    | ASSIGN Exp {  printDerivation("Exp -> Exp ASSIGN error\n"); printSyntaxError("Missing operand before =", (int)$2->line);  }
    | Exp ASSIGN error { printDerivation("Exp -> Exp ASSIGN error\n"); printSyntaxError("Missing operand after =", (int)$2->line); }
    | ID LP error { printDerivation("Exp -> ID LP error\n"); printSyntaxError("Missing closing parenthesis ')'", (int)$2->line); }
    | Exp LB Exp error { printDerivation("Exp -> Exp LB Exp error\n"); printSyntaxError("Missing closing brace ']'", (int)$3->line); }
    | Exp PLUS error { printDerivation("Exp -> Exp PLUS error\n"); printSyntaxError("Missing operand after +", (int)$2->line); }
    | Exp MINUS error { printDerivation("Exp -> Exp MINUS error\n"); printSyntaxError("Missing operand after -", (int)$2->line); }
    | Exp MUL error { printDerivation("Exp -> Exp MUL error\n"); printSyntaxError("Missing operand after *", (int)$2->line); }
    | Exp DIV error { printDerivation("Exp -> Exp DIV error\n"); printSyntaxError("Missing operand after /", (int)$2->line); }
    | LP error { printDerivation("Exp -> LP error\n"); printSyntaxError("Missing closing parenthesis ')'", (int)$1->line); }
    ;

Args: Exp COMMA Args { printDerivation("Args -> Exp COMMA Args\n"); $$ = initParserNode("Args", yylineno); addParserDerivation($$, $1, $2, $3, NULL); cal_line($$);
        symbol_table_insert(temp_member_table, "arg", $1->type);
        $$->value.args_type = ARGS_TYPE_ARGS;
        // $$->ir_list = translate_args($$);
    }
    | Exp { printDerivation("Args -> Exp\n"); $$ = initParserNode("Args", yylineno); addParserDerivation($$, $1, NULL); cal_line($$);
        if(temp_member_table==NULL){
            temp_member_table = symbol_table_init();
        }
        symbol_table_insert(temp_member_table, "arg", $1->type);
        $$->value.args_type = ARGS_TYPE_ARG;
        // $$->ir_list = translate_args($$);
    }
    ;

// phase 2
LC: LCT { printDerivation("LC -> LCT\n"); $$ = initParserNode("LC", yylineno); addParserDerivation($$, $1, NULL); cal_line($$);
        scope_list_add(scope_stack);
    }
    ;

RC: RCT { printDerivation("RC -> RCT\n"); $$ = initParserNode("RC", yylineno); addParserDerivation($$, $1, NULL); cal_line($$);
        temp_member_table = scope_list_pop(scope_stack);
        symbol_table_remove_empty(global_table);
    }
    ;
ID: IDT{ printDerivation("ID -> IDT\n"); $$ = $1; }
    ;

LPF: LP { printDerivation("LPF -> LP\n"); $$ = initParserNode("LPF", yylineno); addParserDerivation($$, $1, NULL); cal_line($$);
        scope_list_add(scope_stack);
}
    ;

RPF: RP { printDerivation("RPF -> RP\n"); $$ = initParserNode("RPF", yylineno); addParserDerivation($$, $1, NULL); cal_line($$);
        // temp_member_table = scope_list_pop(scope_stack);
        // symbol_table_remove_empty(global_table);
}
    ;
%%

void yyerror(const char *s) {
    /* printf("Error type B at Line %d: %s\n", yylineno, s); */
    /* exit(0); */
}

int main(int argc, char **argv){
    char *file_path;
    symbol_table_init_all();
    if(argc < 2) {
        fprintf(stderr, "Usage: %s <file_path>\n", argv[0]);
        return EXIT_FAILURE;
    } else if(argc == 2) {
        file_path = argv[1];
        if(!(yyin = fopen(file_path, "r"))){
            perror(argv[1]);
            return EXIT_FAILURE;
        }
        source_path = (char *) malloc(sizeof(char) * (strlen(file_path) + 1));
        strcpy(source_path, file_path);
        yyparse();
        printParserTree();
        print_ir_list(alloc_ir_list);
        translate_program(rootNode);
        return EXIT_SUCCESS;
    } else {
        fputs("Too many arguments! Expected: 2.\n", stderr);
        return EXIT_FAILURE;
    }
}
