%{
    #include <stdio.h>
    #include <stdlib.h>
    #include <string.h>
    #include <stdarg.h>
    #include "lex.yy.c"
    #include "parser_node.h"
    #include "symbol_table.h"
    // #define YY_USER_ACTION \
    //     yylloc.first_line = yylineno; \
    //     yylloc.first_column = yycolno; \
    //     yylloc.last_line = yylineno; \
    //     yylloc.last_column = yycolno + yyleng; \
    //     yycolno += yyleng;
    // yydebug = 1;

    char *source_path; 
    struct ParserNode * rootNode = NULL; 
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

    symbol_table *global_table = NULL;
    symbol_table *function_table = NULL;
    symbol_table *structure_table = NULL;
    symbol_table *temp_member_table = NULL;
    scope_list *scope_stack = NULL;
    scope_list *structure_stack = NULL;

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
%token <parser_node> TYPE IDT ASSIGN SEMI LITERAL COMMA IF ELSE WHILE FOR RETURN PLUS MINUS MUL DIV EQ NEQ LT GT LEQ GEQ LP RP LB RB LCT RCT AND OR NOT STRUCT DOT

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
Program: ExtDefList { printDerivation("Program -> ExtDefList\n"); $$ = initParserNode("Program", yylineno); rootNode = $$; addParserDerivation($$, $1, NULL); cal_line($$); 
    printf("var table:\n");
    symbol_table_print(global_table);
    printf("\n");
    printf("function table:\n");
    symbol_table_print(function_table);
    printf("\n");
    printf("structure table:\n");
    symbol_table_print(structure_table);
    printf("\n");
}
    ;

ExtDefList: ExtDef ExtDefList { printDerivation("ExtDefList -> ExtDef ExtDefList\n"); $$ = initParserNode("ExtDefList", yylineno); addParserDerivation($$, $1, $2, NULL); cal_line($$); }
    | { printDerivation("ExtDefList -> empty\n"); $$ = initParserNode("ExtDefList", yylineno); $$->empty_value = 1; }
    ;

ExtDef: Specifier ExtDecList SEMI { printDerivation("ExtDef -> Specifier ExtDecList SEMI\n"); $$ = initParserNode("ExtDef", yylineno); addParserDerivation($$, $1, $2, $3, NULL); cal_line($$); 
        passType($2, $1->type);  
}
    | Specifier SEMI { printDerivation("ExtDef -> Specifier SEMI\n"); $$ = initParserNode("ExtDef", yylineno); addParserDerivation($$, $1, $2, NULL); cal_line($$); }
    | Specifier error { printDerivation("ExtDef -> Specifier error\n"); printSyntaxError("Missing semicolon ';'", $1->line);}
    | Specifier ExtDecList error { printDerivation("ExtDef -> Specifier ExtDecList error\n"); printSyntaxError("Missing semicolon ';'", $2->line);}
    | Specifier FunDec CompSt { printDerivation("ExtDef -> Specifier FunDec CompSt\n"); $$ = initParserNode("ExtDef", yylineno); addParserDerivation($$, $1, $2, $3, NULL); cal_line($$); 
    temp_member_table = scope_list_pop(scope_stack);
    symbol_table_remove_empty(global_table);
    memcpy($2->type->function,temp_member_table,sizeof(symbol_table));
    symbol_table_insert($2->type->function,"return_type",$1->type);
    if(check_return_type($3, $1->type)){
        printSemanticError(8, $2->line);
    }
    }
    | ExtDecList SEMI { printDerivation("ExtDef -> ExtDecList SEMI\n"); printSyntaxError("Missing specifier", $1->line);}
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
    Type* type = symbol_table_lookup(structure_table, $2->value.string_value);
    $$->type = type;
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
        if($1->type->category != ARRAY){
            Type *type = (Type *)malloc(sizeof(Type));
            type->category = ARRAY;
            type->array=(Array *)malloc(sizeof(Array));
            type->array->size = $3->value.int_value;
            type->array->base = NULL;
            memcpy($1->type, type, sizeof(Type));
        }else{
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
    | IDT LP RP { printDerivation("FunDec -> ID LP RP\n"); $$ = initParserNode("FunDec", yylineno); addParserDerivation($$, $1, $2, $3, NULL); cal_line($$); 
        Type *type = (Type *)malloc(sizeof(Type));
        type->category = FUNCTION;
        type->function = symbol_table_init();
        Type *return_type = (Type *)malloc(sizeof(Type));
        symbol_table_insert(type->function, $1->value.string_value, return_type); 
        $$->type = type;
        if(function_declare(function_table, $1->value.string_value, type)){
            printSemanticError(4, $1->line);
        }
        temp_member_table = symbol_table_init();
    }
    | IDT LP error { printDerivation("FunDec -> ID LP error\n"); printSyntaxError("Missing closing parenthesis ')'",$2->line); }
    ;

VarList: ParamDec COMMA VarList { printDerivation("VarList -> ParamDec COMMA VarList\n"); $$ = initParserNode("VarList", yylineno); addParserDerivation($$, $1, $2, $3, NULL); cal_line($$); }
    | ParamDec { printDerivation("VarList -> ParamDec\n"); $$ = initParserNode("VarList", yylineno); addParserDerivation($$, $1, NULL); cal_line($$); }
    ;

ParamDec: Specifier VarDec { printDerivation("ParamDec -> Specifier VarDec\n"); $$ = initParserNode("ParamDec", yylineno); addParserDerivation($$, $1, $2, NULL); cal_line($$); }
    ;

CompSt: LC DefList StmtList RC { printDerivation("CompSt -> LC DefList StmtList RC\n"); $$ = initParserNode("CompSt", yylineno); addParserDerivation($$, $1, $2, $3, $4, NULL); cal_line($$); }
    | LC DefList StmtList error { printDerivation("CompSt -> LC DefList StmtList error\n"); printSyntaxError("Missing closing bracket '}'", (int)$3->line); }
    ;

StmtList: Stmt StmtList { printDerivation("StmtList -> Stmt StmtList\n"); $$ = initParserNode("StmtList", yylineno); addParserDerivation($$, $1, $2, NULL); cal_line($$); }
    | Stmt Def StmtList {printDerivation("StmtList -> Stmt Def StmtList\n"); printSyntaxError("Missing specifier", $$->line);}
    | Stmt Def Def StmtList {printDerivation("StmtList -> Stmt Def StmtList\n"); printSyntaxError("Missing specifier", $$->line);}
    | Stmt Def Def Def StmtList {printDerivation("StmtList -> Stmt Def StmtList\n"); printSyntaxError("Missing specifier", $$->line);}
    | Stmt Def Def Def Def StmtList {printDerivation("StmtList -> Stmt Def StmtList\n"); printSyntaxError("Missing specifier", $$->line);}
    | { printDerivation("StmtList -> empty\n"); $$ = initParserNode("StmtList", yylineno); $$->empty_value = 1; }
;

Stmt: Exp SEMI { printDerivation("Stmt -> Exp SEMI\n"); $$ = initParserNode("Stmt", yylineno); addParserDerivation($$, $1, $2, NULL); cal_line($$); }
    | Exp error { printDerivation("Stmt -> Exp error\n"); printSyntaxError("Missing semicolon ';'", $1->line);}
    | CompSt { printDerivation("Stmt -> CompSt\n"); $$ = initParserNode("Stmt", yylineno); addParserDerivation($$, $1, NULL); cal_line($$); }
    | RETURN Exp SEMI { printDerivation("Stmt -> RETURN Exp SEMI\n"); $$ = initParserNode("Stmt", yylineno); addParserDerivation($$, $1, $2, $3, NULL); cal_line($$); }
    | RETURN Exp error { printDerivation("Stmt -> RETURN Exp error\n"); printSyntaxError("Missing semicolon ';'", $2->line);}
    | IF LP Exp RP Stmt { printDerivation("Stmt -> IF LP Exp RP Stmt\n"); $$ = initParserNode("Stmt", yylineno); addParserDerivation($$, $1, $2, $3, $4, $5, NULL); cal_line($$); }
    | IF LP Exp RP Stmt ELSE Stmt { printDerivation("Stmt -> IF LP Exp RP Stmt ELSE Stmt\n"); $$ = initParserNode("Stmt", yylineno); addParserDerivation($$, $1, $2, $3, $4, $5, $6, $7, NULL); cal_line($$); }
    | IF LP error { printDerivation("Stmt -> IF LP error\n"); printSyntaxError("Missing closing parenthesis ')'", (int)$2->line); }
    | IF error Exp RP Stmt { printDerivation("Stmt -> IF error Exp RP Stmt\n"); printSyntaxError("Missing start parenthesis '('", (int)$3->line); }
    | IF error Exp RP Stmt ELSE Stmt { printDerivation("Stmt -> IF error Exp RP Stmt ELSE Stmt\n"); printSyntaxError("Missing start parenthesis '('", (int)$3->line); }
    | ELSE Stmt { printDerivation("Stmt -> ELSE Stmt\n"); $$ = initParserNode("Stmt", yylineno); printSyntaxError("Lack IF for ELSE", (int)$1->line); }
    | WHILE LP Exp RP Stmt { printDerivation("Stmt -> WHILE LP Exp RP Stmt\n"); $$ = initParserNode("Stmt", yylineno); addParserDerivation($$, $1, $2, $3, $4, $5, NULL); cal_line($$); }
    | WHILE LP error {printDerivation("Stmt -> WHILE LP error\n"); printSyntaxError("Missing closing parenthesis ')'", (int)$2->line);}
    | WHILE error Exp RP Stmt { printDerivation("Stmt -> WHILE error Exp RP Stmt\n"); printSyntaxError("Missing start parenthesis '('", (int)$3->line); }
    | FOR LP Exp SEMI Exp SEMI Exp RP Stmt { printDerivation("Stmt -> FOR LP Exp SEMI Exp SEMI Exp RP Semt\n"); $$ = initParserNode("Stmt", yylineno); addParserDerivation($$, $1, $2, $3, $4, $5, $6, $7, $8, $9, NULL); cal_line($$);}
    | FOR LP Def Exp SEMI Exp RP Stmt { printDerivation("Stmt -> FOR LP Def Exp SEMI Exp RP Stmt\n"); $$ = initParserNode("Stmt", yylineno); addParserDerivation($$, $1, $2, $3, $4, $5, $6, $7, $8, NULL); cal_line($$); }
    | FOR LP error { printDerivation("Stmt -> FOR LP error\n"); printSyntaxError("Missing closing parenthesis ')'", (int)$2->line); }
    ;

DefList: Def DefList { printDerivation("DefList -> Def DefList\n"); $$ = initParserNode("DefList", yylineno); addParserDerivation($$, $1, $2, NULL); cal_line($$); }
    | { printDerivation("DefList -> empty\n"); $$ = initParserNode("DefList", yylineno); $$->empty_value = 1; }
    ;

Def: Specifier DecList SEMI { printDerivation("Def -> Specifier DecList SEMI\n"); $$ = initParserNode("Def", yylineno); addParserDerivation($$, $1, $2, $3, NULL); cal_line($$);
        // if ($1->type==NULL){
            // undefined structure
        // } 
        passType($2, $1->type); 
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

Dec: VarDec { printDerivation("Dec -> VarDec\n"); $$ = initParserNode("Dec", yylineno); addParserDerivation($$, $1, NULL); cal_line($$); $$->type = $1->type; }
    | VarDec ASSIGN Exp { printDerivation("Dec -> VarDec ASSIGN Exp\n"); $$ = initParserNode("Dec", yylineno); addParserDerivation($$, $1, $2, $3, NULL); cal_line($$); $$->type = $1->type; }
    ;

Exp: Exp ASSIGN Exp { printDerivation("Exp -> Exp ASSIGN Exp\n"); $$ = initParserNode("Exp", yylineno); addParserDerivation($$, $1, $2, $3, NULL); cal_line($$); 
        if(typeNotMatch($1, $3)) 
            printSemanticError(5, $1->line); 
        if(!$1->is_left_value)
            printSemanticError(6, $1->line);
    }
    | ASSIGN Exp {  printDerivation("Exp -> Exp ASSIGN error\n"); printSyntaxError("Missing operand before =", (int)$2->line);  }
    | Exp ASSIGN error { printDerivation("Exp -> Exp ASSIGN error\n"); printSyntaxError("Missing operand after =", (int)$2->line); }
    | Exp OR Exp { printDerivation("Exp -> Exp OR Exp\n"); $$ = initParserNode("Exp", yylineno); addParserDerivation($$, $1, $2, $3, NULL); cal_line($$); if(typeNotMatch($1, $3)) printSemanticError(7, $1->line); }
    | Exp AND Exp { printDerivation("Exp -> Exp AND Exp\n"); $$ = initParserNode("Exp", yylineno); addParserDerivation($$, $1, $2, $3, NULL); cal_line($$); if(typeNotMatch($1, $3)) printSemanticError(7, $1->line); }
    | Exp EQ Exp { printDerivation("Exp -> Exp EQ Exp\n"); $$ = initParserNode("Exp", yylineno); addParserDerivation($$, $1, $2, $3, NULL); cal_line($$); if(typeNotMatch($1, $3)) printSemanticError(7, $1->line); }
    | Exp NEQ Exp { printDerivation("Exp -> Exp NEQ Exp\n"); $$ = initParserNode("Exp", yylineno); addParserDerivation($$, $1, $2, $3, NULL); cal_line($$); if(typeNotMatch($1, $3)) printSemanticError(7, $1->line); }
    | Exp LT Exp { printDerivation("Exp -> Exp LT Exp\n"); $$ = initParserNode("Exp", yylineno); addParserDerivation($$, $1, $2, $3, NULL); cal_line($$); if(typeNotMatch($1, $3)) printSemanticError(7, $1->line); }
    | Exp GT Exp { printDerivation("Exp -> Exp GT Exp\n"); $$ = initParserNode("Exp", yylineno); addParserDerivation($$, $1, $2, $3, NULL); cal_line($$); if(typeNotMatch($1, $3)) printSemanticError(7, $1->line); }
    | Exp LEQ Exp { printDerivation("Exp -> Exp LEQ Exp\n"); $$ = initParserNode("Exp", yylineno); addParserDerivation($$, $1, $2, $3, NULL); cal_line($$); if(typeNotMatch($1, $3)) printSemanticError(7, $1->line); }
    | Exp GEQ Exp { printDerivation("Exp -> Exp GEQ Exp\n"); $$ = initParserNode("Exp", yylineno); addParserDerivation($$, $1, $2, $3, NULL); cal_line($$); if(typeNotMatch($1, $3)) printSemanticError(7, $1->line); }
    | Exp PLUS Exp { printDerivation("Exp -> Exp PLUS Exp\n"); $$ = initParserNode("Exp", yylineno); addParserDerivation($$, $1, $2, $3, NULL); cal_line($$); if(typeNotMatch($1, $3)) printSemanticError(7, $1->line); }
    | Exp MINUS Exp { printDerivation("Exp -> Exp MINUS Exp\n"); $$ = initParserNode("Exp", yylineno); addParserDerivation($$, $1, $2, $3, NULL); cal_line($$); if(typeNotMatch($1, $3)) printSemanticError(7, $1->line); }
    | Exp MUL Exp { printDerivation("Exp -> Exp MUL Exp\n"); $$ = initParserNode("Exp", yylineno); addParserDerivation($$, $1, $2, $3, NULL); cal_line($$); if(typeNotMatch($1, $3)) printSemanticError(7, $1->line); }
    | Exp DIV Exp { printDerivation("Exp -> Exp DIV Exp\n"); $$ = initParserNode("Exp", yylineno); addParserDerivation($$, $1, $2, $3, NULL); cal_line($$); if(typeNotMatch($1, $3)) printSemanticError(7, $1->line); }
    | Exp PLUS error { printDerivation("Exp -> Exp PLUS error\n"); printSyntaxError("Missing operand after +", (int)$2->line); }
    | Exp MINUS error { printDerivation("Exp -> Exp MINUS error\n"); printSyntaxError("Missing operand after -", (int)$2->line); }
    | Exp MUL error { printDerivation("Exp -> Exp MUL error\n"); printSyntaxError("Missing operand after *", (int)$2->line); }
    | Exp DIV error { printDerivation("Exp -> Exp DIV error\n"); printSyntaxError("Missing operand after /", (int)$2->line); }
    | LP Exp RP { printDerivation("Exp -> LP Exp RP\n"); $$ = initParserNode("Exp", yylineno); addParserDerivation($$, $1, $2, $3, NULL); cal_line($$); }
    | LP error { printDerivation("Exp -> LP error\n"); printSyntaxError("Missing closing parenthesis ')'", (int)$1->line); }
    // | MINUS Exp %prec UMINUS 
    | PLUS Exp { printDerivation("Exp -> PLUS Exp\n"); $$ = initParserNode("Exp", yylineno); addParserDerivation($$, $1, $2, NULL); cal_line($$); }
    | MINUS Exp { printDerivation("Exp -> MINUS Exp\n"); $$ = initParserNode("Exp", yylineno); addParserDerivation($$, $1, $2, NULL); cal_line($$); }
    | NOT Exp { printDerivation("Exp -> NOT Exp\n"); $$ = initParserNode("Exp", yylineno); addParserDerivation($$, $1, $2, NULL); cal_line($$); }
    | ID LP Args RP { printDerivation("Exp -> ID LP Args RP\n"); $$ = initParserNode("Exp", yylineno); addParserDerivation($$, $1, $2, $3, $4, NULL); cal_line($$); 
        Type *type = symbol_table_lookup(function_table, $1->value.string_value);
        if(type == NULL){
            printSemanticError(2, $1->line);
            $$->type=NULL;
        }
        else if(type->category != FUNCTION){
            // not used
            printSemanticError(11, $1->line);
            $$->type=NULL;
        }
        else{
            if(check_function_args(type->function, temp_member_table)){
                printSemanticError(9, $1->line);
            }
            temp_member_table = symbol_table_init();
            $$->type = type->function->head->list->head->type;
        }
    }
    | ID LP RP { printDerivation("Exp -> ID LP RP\n"); $$ = initParserNode("Exp", yylineno); addParserDerivation($$, $1, $2, $3, NULL); cal_line($$); 
        Type *type = symbol_table_lookup(function_table, $1->value.string_value);
        if(type == NULL){
            printSemanticError(2, $1->line);
            $$->type=NULL;
        }
        else if(type->category != FUNCTION){
            // not used
            printSemanticError(11, $1->line);
            $$->type=NULL;
        }else{
            if(check_function_args(type->function, NULL)){
                printSemanticError(9, $1->line);
            }
            $$->type = type->function->head->list->head->type;
        }
    }
    | ID LP error { printDerivation("Exp -> ID LP error\n"); printSyntaxError("Missing closing parenthesis ')'", (int)$2->line); }
    | Exp LB Exp RB { printDerivation("Exp -> Exp LB Exp RB\n"); $$ = initParserNode("Exp", yylineno); $$->is_left_value = 1; addParserDerivation($$, $1, $2, $3, $4, NULL); cal_line($$); 
        if($1->type->category != ARRAY){
            printSemanticError(10, $1->line);
        }else{
            if($3->type->category != PRIMITIVE || $3->type->primitive != SEMANTIC_TYPE_INT){
                printSemanticError(12, $3->line);
            }else{
            $$->type = $1->type->array->base;
            }
        }
    }
    | Exp LB Exp error { printDerivation("Exp -> Exp LB Exp error\n"); printSyntaxError("Missing closing brace ']'", (int)$3->line); }
    | Exp DOT ID { printDerivation("Exp -> Exp DOT ID\n"); $$ = initParserNode("Exp", yylineno); $$->is_left_value = 1; addParserDerivation($$, $1, $2, $3, NULL); cal_line($$); 
        if($1->type->category != STRUCTURE){
            printSemanticError(13, $1->line);
            $$->type = NULL;
        }else{
            Type *type = symbol_table_lookup($1->type->structure, $3->value.string_value);
            if(type == NULL){
                printSemanticError(14, $3->line);
            }
            $$->type = type;
        }
    }
    | ID { printDerivation("Exp -> ID\n"); $$ = initParserNode("Exp", yylineno); $$->is_left_value = 1; addParserDerivation($$, $1, NULL); cal_line($$); 
        Type* type = symbol_table_lookup(global_table, $1->value.string_value);
        if(type == NULL){
            printSemanticError(1, $1->line);
        }
        $$->type = type;
    }
    | INT { printDerivation("Exp -> INT\n"); $$ = initParserNode("Exp", yylineno); addParserDerivation($$, $1, NULL); cal_line($$); }
    | FLOAT { printDerivation("Exp -> FLOAT\n"); $$ = initParserNode("Exp", yylineno); addParserDerivation($$, $1, NULL); cal_line($$); }
    | CHAR { printDerivation("Exp -> CHAR\n"); $$ = initParserNode("Exp", yylineno); addParserDerivation($$, $1, NULL); cal_line($$); }
    | LITERAL { printDerivation("Exp -> LITERAL\n"); $$ = initParserNode("Exp", yylineno); addParserDerivation($$, $1, NULL); cal_line($$); }
    ;

Args: Exp COMMA Args { printDerivation("Args -> Exp COMMA Args\n"); $$ = initParserNode("Args", yylineno); addParserDerivation($$, $1, $2, $3, NULL); cal_line($$); 
        symbol_table_insert(temp_member_table, "arg", $1->type);
    }
    | Exp { printDerivation("Args -> Exp\n"); $$ = initParserNode("Args", yylineno); addParserDerivation($$, $1, NULL); cal_line($$); 
        symbol_table_insert(temp_member_table, "arg", $1->type);
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
ID: IDT{printDerivation("ID -> IDT\n"); $$ = $1; }
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
    global_table = symbol_table_init();
    function_table = symbol_table_init();
    structure_table = symbol_table_init();
    scope_stack = scope_list_init();
    structure_stack = scope_list_init();
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
        return EXIT_SUCCESS;
    } else {
        fputs("Too many arguments! Expected: 2.\n", stderr);
        return EXIT_FAILURE;
    }
}
