%{
    #include <stdio.h>
    #include <stdlib.h>
    #include <string.h>
    #include "lex.yy.c"
    // #define YY_USER_ACTION \
    //     yylloc.first_line = yylineno; \
    //     yylloc.first_column = yycolno; \
    //     yylloc.last_line = yylineno; \
    //     yylloc.last_column = yycolno + yyleng; \
    //     yycolno += yyleng;
    void yyerror(const char*);
    struct ParserNode{
        char *name;
        int line;
        int child_num;
        struct ParserNode *child[10];
        char *value;
    };
%}

%union {
    int int_value;
    float float_value;
    char *string_value;
}

%token <int_value> INT
%token <float_value> FLOAT
%token <string_value> CHAR
%token <string_value> TYPE ID ASSIGN SEMI LITERAL COMMA IF ELSE WHILE RETURN PLUS MINUS MUL DIV EQ NEQ LT GT LEQ GEQ LP RP LB RB LC RC AND OR NOT STRUCT DOT

%right ASSIGN
%left OR
%left AND
%left LT GT LEQ GEQ EQ NEQ
%left PLUS MINUS
%left MUL DIV
%right NOT
%left LP RP LB RB LC RC DOT
%nonassoc ELSE

%%

Program: ExtDefList { printf("Program -> ExtDefList\n");}
    ;

ExtDefList: ExtDef ExtDefList {printf("ExtDefList -> ExtDef ExtDefList\n");}
    | {printf("ExtDefList -> empty\n");}
    ;

ExtDef: Specifier ExtDecList SEMI {printf("ExtDef -> Specifier ExtDecList SEMI\n");}
    | Specifier SEMI {printf("ExtDef -> Specifier SEMI\n");}
    | Specifier FunDec CompSt {printf("ExtDef -> Specifier FunDec CompSt\n");}
    ;

ExtDecList: VarDec {printf("ExtDecList -> VarDec\n");}
    | VarDec COMMA ExtDecList {printf("ExtDecList -> VarDec COMMA ExtDecList\n");}
    ;

Specifier: TYPE {printf("Specifier -> TYPE\n");}
    | StructSpecifier {printf("Specifier -> StructSpecifier\n");}
    ;

StructSpecifier: STRUCT ID LC DefList RC {printf("StructSpecifier -> STRUCT ID LC DefList RC\n");}
    | STRUCT ID {printf("StructSpecifier -> STRUCT ID\n");}
    ;

VarDec: ID {printf("VarDec -> ID\n");}
    | VarDec LB INT RB {printf("VarDec -> VarDec LB INT RB\n");}
    ;

FunDec: ID LP VarList RP {printf("FunDec -> ID LP VarList RP\n");}
    | ID LP RP {printf("FunDec -> ID LP RP\n");}
    ;

VarList: ParamDec COMMA VarList {printf("VarList -> ParamDec COMMA VarList\n");}
    | ParamDec {printf("VarList -> ParamDec\n");}
    ;

ParamDec: Specifier VarDec {printf("ParamDec -> Specifier VarDec\n");}
    ;

CompSt: LC DefList StmtList RC {printf("CompSt -> LC DefList StmtList RC\n");}
    ;

StmtList: Stmt StmtList {printf("StmtList -> Stmt StmtList\n");}
    | {printf("StmtList -> empty\n");}
    ;

Stmt: Exp SEMI {printf("Stmt -> Exp SEMI\n"); }
    | CompSt {printf("Stmt -> CompSt\n");}
    | RETURN Exp SEMI {printf("Stmt -> RETURN Exp SEMI\n");}
    | IF LP Exp RP Stmt {printf("Stmt -> IF LP Exp RP Stmt\n");}
    | IF LP Exp RP Stmt ELSE Stmt {printf("Stmt -> IF LP Exp RP Stmt ELSE Stmt\n");}
    | WHILE LP Exp RP Stmt {printf("Stmt -> WHILE LP Exp RP Stmt\n");}
    ;

DefList: Def DefList {printf("DefList -> Def DefList\n");}
    | {printf("DefList -> empty\n");}
    ;

Def: Specifier DecList SEMI {printf("Def -> Specifier DecList SEMI\n");}
    ;

DecList: Dec {printf("DecList -> Dec\n");}
    | Dec COMMA DecList {printf("DecList -> Dec COMMA DecList\n");}
    ;

Dec: VarDec {printf("Dec -> VarDec\n");}
    | VarDec ASSIGN Exp {printf("Dec -> VarDec ASSIGN Exp\n");}
    ;

Exp: Exp ASSIGN Exp {printf("Exp -> Exp ASSIGN Exp\n");}
    | Exp OR Exp {printf("Exp -> Exp OR Exp\n");}
    | Exp AND Exp {printf("Exp -> Exp AND Exp\n");}
    | Exp EQ Exp {printf("Exp -> Exp EQ Exp\n");}
    | Exp NEQ Exp {printf("Exp -> Exp NEQ Exp\n");}
    | Exp LT Exp {printf("Exp -> Exp LT Exp\n");}
    | Exp GT Exp {printf("Exp -> Exp GT Exp\n");}
    | Exp LEQ Exp {printf("Exp -> Exp LEQ Exp\n");}
    | Exp GEQ Exp {printf("Exp -> Exp GEQ Exp\n");}
    | Exp PLUS Exp {printf("Exp -> Exp PLUS Exp\n");}
    | Exp MINUS Exp {printf("Exp -> Exp MINUS Exp\n");}
    | Exp MUL Exp {printf("Exp -> Exp MUL Exp\n");}
    | Exp DIV Exp {printf("Exp -> Exp DIV Exp\n");}
    | LP Exp RP {printf("Exp -> LP Exp RP\n");}
    /* | MINUS Exp %prec UMINUS */
    | MINUS Exp {printf("Exp -> MINUS Exp\n");}
    | NOT Exp {printf("Exp -> NOT Exp\n");}
    | ID LP Args RP {printf("Exp -> ID LP Args RP\n");}
    | ID LP RP {printf("Exp -> ID LP RP\n");}
    | Exp LB Exp RB {printf("Exp -> Exp LB Exp RB\n");}
    | Exp DOT ID {printf("Exp -> Exp DOT ID\n");}
    | ID {printf("Exp -> ID\n");}
    | INT {printf("Exp -> INT\n");}
    | FLOAT {printf("Exp -> FLOAT\n");}
    | CHAR {printf("Exp -> CHAR\n");}
    | LITERAL {printf("Exp -> LITERAL\n");}
    ;

Args: Exp COMMA Args {printf("Args -> Exp COMMA Args\n");}
    | Exp {printf("Args -> Exp\n");}
    ;

%%

void yyerror(const char *s) {
    fprintf(stderr, "%s\n", s);
}

int main(int argc, char **argv){
    char *file_path;
    if(argc < 2) {
        fprintf(stderr, "Usage: %s <file_path>\n", argv[0]);
        return EXIT_FAILURE;
    } else if(argc == 2) {
        file_path = argv[1];
        if(!(yyin = fopen(file_path, "r"))){
            perror(argv[1]);
            return EXIT_FAILURE;
        }
        yyparse();
        return EXIT_SUCCESS;
    } else {
        fputs("Too many arguments! Expected: 2.\n", stderr);
        return EXIT_FAILURE;
    }
}
