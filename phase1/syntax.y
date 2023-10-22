%{
    #include <stdio.h>
    #include <stdlib.h>
    #include <string.h>
    #include <stdarg.h>
    #include "lex.yy.c"
    #include "parser_node.h"
    // #define YY_USER_ACTION \
    //     yylloc.first_line = yylineno; \
    //     yylloc.first_column = yycolno; \
    //     yylloc.last_line = yylineno; \
    //     yylloc.last_column = yycolno + yyleng; \
    //     yycolno += yyleng;
    // yydebug = 1;

    struct ParserNode * rootNode = NULL;

    void yyerror(const char*);

    void addParserDerivation(struct ParserNode *node, ...) {
        // return;
        va_list args;
        va_start(args, node);
        while(1) {
            struct ParserNode *child = va_arg(args, struct ParserNode*);
            if(child == NULL) break;
            addParserNode(node, child);
        }
        va_end(args);
    }

    void printParserTree() {
#ifndef PRINT_PARSER_TREE
        return;
#endif
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
%token <parser_node> TYPE ID ASSIGN SEMI LITERAL COMMA IF ELSE WHILE RETURN PLUS MINUS MUL DIV EQ NEQ LT GT LEQ GEQ LP RP LB RB LC RC AND OR NOT STRUCT DOT

%right ASSIGN
%left OR
%left AND
%left LT GT LEQ GEQ EQ NEQ
%left PLUS MINUS
%left MUL DIV
%right NOT
%left LP RP LB RB LC RC DOT
%nonassoc ELSE

%type <parser_node> Program ExtDefList ExtDef ExtDecList Specifier StructSpecifier VarDec FunDec VarList ParamDec CompSt StmtList Stmt DefList Def DecList Dec Exp Args

%%

Program: ExtDefList { printDerivation("Program -> ExtDefList\n"); $$ = initParserNode("Program"); rootNode = $$; addParserDerivation($$, $1, NULL); }
    ;

ExtDefList: ExtDef ExtDefList { printDerivation("ExtDefList -> ExtDef ExtDefList\n"); $$ = initParserNode("ExtDefList"); addParserDerivation($$, $1, $2, NULL); }
    | { printDerivation("ExtDefList -> empty\n"); $$ = initParserNode("ExtDefList"); }
    ;

ExtDef: Specifier ExtDecList SEMI { printDerivation("ExtDef -> Specifier ExtDecList SEMI\n"); $$ = initParserNode("ExtDef"); addParserDerivation($$, $1, $2, $3, NULL); }
    | Specifier SEMI { printDerivation("ExtDef -> Specifier SEMI\n"); $$ = initParserNode("ExtDef"); addParserDerivation($$, $1, NULL); }
    | Specifier FunDec CompSt { printDerivation("ExtDef -> Specifier FunDec CompSt\n"); $$ = initParserNode("ExtDef"); addParserDerivation($$, $1, $2, $3, NULL); }
    ;

ExtDecList: VarDec { printDerivation("ExtDecList -> VarDec\n"); $$ = initParserNode("ExtDecList"); addParserDerivation($$, $1, NULL); }
    | VarDec COMMA ExtDecList { printDerivation("ExtDecList -> VarDec COMMA ExtDecList\n"); $$ = initParserNode("ExtDecList"); addParserDerivation($$, $1, $2, $3, NULL); }
    ;

Specifier: TYPE { printDerivation("Specifier -> TYPE\n"); $$ = initParserNode("Specifier"); addParserDerivation($$, $1, NULL); }
    | StructSpecifier { printDerivation("Specifier -> StructSpecifier\n"); $$ = initParserNode("Specifier"); addParserDerivation($$, $1, NULL); }
    ;

StructSpecifier: STRUCT ID LC DefList RC { printDerivation("StructSpecifier -> STRUCT ID LC DefList RC\n"); $$ = initParserNode("StructSpecifier"); addParserDerivation($$, $1, $2, $3, $4, NULL); }
    | STRUCT ID { printDerivation("StructSpecifier -> STRUCT ID\n"); $$ = initParserNode("StructSpecifier"); addParserDerivation($$, $1, $2, NULL); }
    ;

VarDec: ID { printDerivation("VarDec -> ID\n"); $$ = initParserNode("VarDec"); addParserDerivation($$, $1, NULL); }
    | VarDec LB INT RB { printDerivation("VarDec -> VarDec LB INT RB\n"); $$ = initParserNode("VarDec"); addParserDerivation($$, $1, $2, $3, $4, NULL); }
    ;

FunDec: ID LP VarList RP { printDerivation("FunDec -> ID LP VarList RP\n"); $$ = initParserNode("FunDec"); addParserDerivation($$, $1, $2, $3, $4, NULL); }
    | ID LP RP { printDerivation("FunDec -> ID LP RP\n"); $$ = initParserNode("FunDec"); addParserDerivation($$, $1, $2, NULL); }
    ;

VarList: ParamDec COMMA VarList { printDerivation("VarList -> ParamDec COMMA VarList\n"); $$ = initParserNode("VarList"); addParserDerivation($$, $1, $2, $3, NULL); }
    | ParamDec { printDerivation("VarList -> ParamDec\n"); $$ = initParserNode("VarList"); addParserDerivation($$, $1, NULL); }
    ;

ParamDec: Specifier VarDec { printDerivation("ParamDec -> Specifier VarDec\n"); $$ = initParserNode("ParamDec"); addParserDerivation($$, $1, $2, NULL); }
    ;

CompSt: LC DefList StmtList RC { printDerivation("CompSt -> LC DefList StmtList RC\n"); $$ = initParserNode("CompSt"); addParserDerivation($$, $1, $2, $3, $4, NULL); }
    ;

StmtList: Stmt StmtList { printDerivation("StmtList -> Stmt StmtList\n"); $$ = initParserNode("StmtList"); addParserDerivation($$, $1, $2, NULL); }
    | { printDerivation("StmtList -> empty\n"); $$ = initParserNode("StmtList"); }
    ;

Stmt: Exp SEMI { printDerivation("Stmt -> Exp SEMI\n"); $$ = initParserNode("Stmt"); addParserDerivation($$, $1, NULL); }
    | CompSt { printDerivation("Stmt -> CompSt\n"); $$ = initParserNode("Stmt"); addParserDerivation($$, $1, NULL); }
    | RETURN Exp SEMI { printDerivation("Stmt -> RETURN Exp SEMI\n"); $$ = initParserNode("Stmt"); addParserDerivation($$, $1, $2, NULL); }
    | IF LP Exp RP Stmt { printDerivation("Stmt -> IF LP Exp RP Stmt\n"); $$ = initParserNode("Stmt"); addParserDerivation($$, $1, $2, $3, $4, $5, NULL); }
    | IF LP Exp RP Stmt ELSE Stmt { printDerivation("Stmt -> IF LP Exp RP Stmt ELSE Stmt\n"); $$ = initParserNode("Stmt"); addParserDerivation($$, $1, $2, $3, $4, $5, $6, NULL); }
    | WHILE LP Exp RP Stmt { printDerivation("Stmt -> WHILE LP Exp RP Stmt\n"); $$ = initParserNode("Stmt"); addParserDerivation($$, $1, $2, $3, $4, $5, NULL); }
    ;

DefList: Def DefList { printDerivation("DefList -> Def DefList\n"); $$ = initParserNode("DefList"); addParserDerivation($$, $1, $2, NULL); }
    | { printDerivation("DefList -> empty\n"); $$ = initParserNode("DefList"); }
    ;

Def: Specifier DecList SEMI { printDerivation("Def -> Specifier DecList SEMI\n"); $$ = initParserNode("Def"); addParserDerivation($$, $1, $2, $3, NULL); }
    ;

DecList: Dec { printDerivation("DecList -> Dec\n"); $$ = initParserNode("DecList"); addParserDerivation($$, $1, NULL); }
    | Dec COMMA DecList { printDerivation("DecList -> Dec COMMA DecList\n"); $$ = initParserNode("DecList"); addParserDerivation($$, $1, $2, $3, NULL); }
    ;

Dec: VarDec { printDerivation("Dec -> VarDec\n"); $$ = initParserNode("Dec"); addParserDerivation($$, $1, NULL); }
    | VarDec ASSIGN Exp { printDerivation("Dec -> VarDec ASSIGN Exp\n"); $$ = initParserNode("Dec"); addParserDerivation($$, $1, $2, $3, NULL); }
    ;

Exp: Exp ASSIGN Exp { printDerivation("Exp -> Exp ASSIGN Exp\n"); $$ = initParserNode("Exp"); addParserDerivation($$, $1, $2, $3, NULL); }
    | Exp OR Exp { printDerivation("Exp -> Exp OR Exp\n"); $$ = initParserNode("Exp"); addParserDerivation($$, $1, $2, $3, NULL); }
    | Exp AND Exp { printDerivation("Exp -> Exp AND Exp\n"); $$ = initParserNode("Exp"); addParserDerivation($$, $1, $2, $3, NULL); }
    | Exp EQ Exp { printDerivation("Exp -> Exp EQ Exp\n"); $$ = initParserNode("Exp"); addParserDerivation($$, $1, $2, $3, NULL); }
    | Exp NEQ Exp { printDerivation("Exp -> Exp NEQ Exp\n"); $$ = initParserNode("Exp"); addParserDerivation($$, $1, $2, $3, NULL); }
    | Exp LT Exp { printDerivation("Exp -> Exp LT Exp\n"); $$ = initParserNode("Exp"); addParserDerivation($$, $1, $2, $3, NULL); }
    | Exp GT Exp { printDerivation("Exp -> Exp GT Exp\n"); $$ = initParserNode("Exp"); addParserDerivation($$, $1, $2, $3, NULL); }
    | Exp LEQ Exp { printDerivation("Exp -> Exp LEQ Exp\n"); $$ = initParserNode("Exp"); addParserDerivation($$, $1, $2, $3, NULL); }
    | Exp GEQ Exp { printDerivation("Exp -> Exp GEQ Exp\n"); $$ = initParserNode("Exp"); addParserDerivation($$, $1, $2, $3, NULL); }
    | Exp PLUS Exp { printDerivation("Exp -> Exp PLUS Exp\n"); $$ = initParserNode("Exp"); addParserDerivation($$, $1, $2, $3, NULL); }
    | Exp MINUS Exp { printDerivation("Exp -> Exp MINUS Exp\n"); $$ = initParserNode("Exp"); addParserDerivation($$, $1, $2, $3, NULL); }
    | Exp MUL Exp { printDerivation("Exp -> Exp MUL Exp\n"); $$ = initParserNode("Exp"); addParserDerivation($$, $1, $2, $3, NULL); }
    | Exp DIV Exp { printDerivation("Exp -> Exp DIV Exp\n"); $$ = initParserNode("Exp"); addParserDerivation($$, $1, $2, $3, NULL); }
    | LP Exp RP { printDerivation("Exp -> LP Exp RP\n"); $$ = initParserNode("Exp"); addParserDerivation($$, $1, $2, $3, NULL); }
    // | MINUS Exp %prec UMINUS 
    | MINUS Exp { printDerivation("Exp -> MINUS Exp\n"); $$ = initParserNode("Exp"); addParserDerivation($$, $1, $2, NULL); }
    | NOT Exp { printDerivation("Exp -> NOT Exp\n"); $$ = initParserNode("Exp"); addParserDerivation($$, $1, $2, NULL); }
    | ID LP Args RP { printDerivation("Exp -> ID LP Args RP\n"); $$ = initParserNode("Exp"); addParserDerivation($$, $1, $2, $3, $4, NULL); }
    | ID LP RP { printDerivation("Exp -> ID LP RP\n"); $$ = initParserNode("Exp"); addParserDerivation($$, $1, $2, NULL); }
    | Exp LB Exp RB { printDerivation("Exp -> Exp LB Exp RB\n"); $$ = initParserNode("Exp"); addParserDerivation($$, $1, $2, $3, $4, NULL); }
    | Exp DOT ID { printDerivation("Exp -> Exp DOT ID\n"); $$ = initParserNode("Exp"); addParserDerivation($$, $1, $2, $3, NULL); }
    | ID { printDerivation("Exp -> ID\n"); $$ = initParserNode("Exp"); addParserDerivation($$, $1, NULL); }
    | INT { printDerivation("Exp -> INT\n"); $$ = initParserNode("Exp"); addParserDerivation($$, $1, NULL); }
    | FLOAT { printDerivation("Exp -> FLOAT\n"); $$ = initParserNode("Exp"); addParserDerivation($$, $1, NULL); }
    | CHAR { printDerivation("Exp -> CHAR\n"); $$ = initParserNode("Exp"); addParserDerivation($$, $1, NULL); }
    | LITERAL { printDerivation("Exp -> LITERAL\n"); $$ = initParserNode("Exp"); addParserDerivation($$, $1, NULL); }
    ;

Args: Exp COMMA Args { printDerivation("Args -> Exp COMMA Args\n"); $$ = initParserNode("Args"); addParserDerivation($$, $1, $2, $3, NULL); }
    | Exp { printDerivation("Args -> Exp\n"); $$ = initParserNode("Args"); addParserDerivation($$, $1, NULL); }
    ;

%%

void yyerror(const char *s) {
    /* fprintf(stderr, "%s\n", s); */
    printf("Error type B at Line %d: %s\n", yylineno, s);
    exit(0);
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
        printParserTree();
        return EXIT_SUCCESS;
    } else {
        fputs("Too many arguments! Expected: 2.\n", stderr);
        return EXIT_FAILURE;
    }
}
