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

    char *source_path;
    struct ParserNode * rootNode = NULL;
    int lexeme_error = 0;
    int syntax_error = 0;

    void yyerror(const char*);

    void printSyntaxError(char *s, const int lineno) {
        syntax_error = 1;
        printf("Error type B at Line %d: %s\n", lineno, s);
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
%token <parser_node> TYPE ID ASSIGN SEMI LITERAL COMMA IF ELSE WHILE FOR RETURN PLUS MINUS MUL DIV EQ NEQ LT GT LEQ GEQ LP RP LB RB LC RC AND OR NOT STRUCT DOT

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
/* %type <parser_node> Program ExtDefList ExtDef ExtDecList Specifier StructSpecifier VarDec FunDec VarList ParamDec CompSt StmtList Stmt DefList Def DefMS DecList Dec Exp Args */

%%

Program: ExtDefList { printDerivation("Program -> ExtDefList\n"); $$ = initParserNode("Program", yylineno); rootNode = $$; addParserDerivation($$, $1, NULL); cal_line($$); }
    ;

ExtDefList: ExtDef ExtDefList { printDerivation("ExtDefList -> ExtDef ExtDefList\n"); $$ = initParserNode("ExtDefList", yylineno); addParserDerivation($$, $1, $2, NULL); cal_line($$); }
    | { printDerivation("ExtDefList -> empty\n"); $$ = initParserNode("ExtDefList", yylineno); $$->empty_value = 1; }
    ;

ExtDef: Specifier ExtDecList SEMI { printDerivation("ExtDef -> Specifier ExtDecList SEMI\n"); $$ = initParserNode("ExtDef", yylineno); addParserDerivation($$, $1, $2, $3, NULL); cal_line($$); }
    | Specifier SEMI { printDerivation("ExtDef -> Specifier SEMI\n"); $$ = initParserNode("ExtDef", yylineno); addParserDerivation($$, $1, $2, NULL); cal_line($$); }
    | Specifier error { printDerivation("ExtDef -> Specifier error\n"); printSyntaxError("Missing semicolon ';'", $1->line);}
    | Specifier ExtDecList error { printDerivation("ExtDef -> Specifier ExtDecList error\n"); printSyntaxError("Missing semicolon ';'", $2->line);}
    | Specifier FunDec CompSt { printDerivation("ExtDef -> Specifier FunDec CompSt\n"); $$ = initParserNode("ExtDef", yylineno); addParserDerivation($$, $1, $2, $3, NULL); cal_line($$); }
    ;

ExtDecList: VarDec { printDerivation("ExtDecList -> VarDec\n"); $$ = initParserNode("ExtDecList", yylineno); addParserDerivation($$, $1, NULL); cal_line($$); }
    | VarDec COMMA ExtDecList { printDerivation("ExtDecList -> VarDec COMMA ExtDecList\n"); $$ = initParserNode("ExtDecList", yylineno); addParserDerivation($$, $1, $2, $3, NULL); cal_line($$); }
    ;

Specifier: TYPE { printDerivation("Specifier -> TYPE\n"); $$ = initParserNode("Specifier", yylineno); addParserDerivation($$, $1, NULL); cal_line($$); }
    | StructSpecifier { printDerivation("Specifier -> StructSpecifier\n"); $$ = initParserNode("Specifier", yylineno); addParserDerivation($$, $1, NULL); cal_line($$); }
    ;

StructSpecifier: STRUCT ID LC DefList RC { printDerivation("StructSpecifier -> STRUCT ID LC DefList RC\n"); $$ = initParserNode("StructSpecifier", yylineno); addParserDerivation($$, $1, $2, $3, $4, $5, NULL); cal_line($$); }
    | STRUCT ID { printDerivation("StructSpecifier -> STRUCT ID\n"); $$ = initParserNode("StructSpecifier", yylineno); addParserDerivation($$, $1, $2, NULL); cal_line($$); }
    ;

VarDec: ID { printDerivation("VarDec -> ID\n"); $$ = initParserNode("VarDec", yylineno); addParserDerivation($$, $1, NULL); cal_line($$); }
    | VarDec LB INT RB { printDerivation("VarDec -> VarDec LB INT RB\n"); $$ = initParserNode("VarDec", yylineno); addParserDerivation($$, $1, $2, $3, $4, NULL); cal_line($$); }
    ;

FunDec: ID LP VarList RP { printDerivation("FunDec -> ID LP VarList RP\n"); $$ = initParserNode("FunDec", yylineno); addParserDerivation($$, $1, $2, $3, $4, NULL); cal_line($$); }
    | ID LP RP { printDerivation("FunDec -> ID LP RP\n"); $$ = initParserNode("FunDec", yylineno); addParserDerivation($$, $1, $2, $3, NULL); cal_line($$); }
    | ID LP error { printDerivation("FunDec -> ID LP error\n"); printSyntaxError("Missing closing parenthesis ')'",$2->line); }
    ;

VarList: ParamDec COMMA VarList { printDerivation("VarList -> ParamDec COMMA VarList\n"); $$ = initParserNode("VarList", yylineno); addParserDerivation($$, $1, $2, $3, NULL); cal_line($$); }
    | ParamDec { printDerivation("VarList -> ParamDec\n"); $$ = initParserNode("VarList", yylineno); addParserDerivation($$, $1, NULL); cal_line($$); }
    ;

ParamDec: Specifier VarDec { printDerivation("ParamDec -> Specifier VarDec\n"); $$ = initParserNode("ParamDec", yylineno); addParserDerivation($$, $1, $2, NULL); cal_line($$); }
    ;

CompSt: LC DefList StmtList RC { printDerivation("CompSt -> LC DefList StmtList RC\n"); $$ = initParserNode("CompSt", yylineno); addParserDerivation($$, $1, $2, $3, $4, NULL); cal_line($$); }
    ;

StmtList: Stmt StmtList { printDerivation("StmtList -> Stmt StmtList\n"); $$ = initParserNode("StmtList", yylineno); addParserDerivation($$, $1, $2, NULL); cal_line($$); }
    | Stmt Def StmtList {printDerivation("StmtList -> Stmt Def DefList\n"); printSyntaxError("Missing specifier", $$->line);}
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
    | WHILE LP Exp RP Stmt { printDerivation("Stmt -> WHILE LP Exp RP Stmt\n"); $$ = initParserNode("Stmt", yylineno); addParserDerivation($$, $1, $2, $3, $4, $5, NULL); cal_line($$); }
    | WHILE LP error {printDerivation("Stmt -> WHILE LP error\n");}
    | FOR LP Exp SEMI Exp SEMI Exp RP Stmt { printDerivation("Stmt -> FOR LP Exp SEMI Exp SEMI Exp RP Semt\n"); $$ = initParserNode("Stmt", yylineno); addParserDerivation($$, $1, $2, $3, $4, $5, $6, $7, $8, $9, NULL); cal_line($$);}
    | FOR LP Def Exp SEMI Exp RP Stmt { printDerivation("Stmt -> FOR LP Def Exp SEMI Exp RP Stmt\n"); $$ = initParserNode("Stmt", yylineno); addParserDerivation($$, $1, $2, $3, $4, $5, $6, $7, $8, NULL); cal_line($$); }
    | FOR LP error { printDerivation("Stmt -> FOR LP error\n"); printSyntaxError("Missing closing parenthesis ')'", (int)$2->line); }
    ;

DefList: Def DefList { printDerivation("DefList -> Def DefList\n"); $$ = initParserNode("DefList", yylineno); addParserDerivation($$, $1, $2, NULL); cal_line($$); }
    | { printDerivation("DefList -> empty\n"); $$ = initParserNode("DefList", yylineno); $$->empty_value = 1; }
    ;

Def: Specifier DecList SEMI { printDerivation("Def -> Specifier DecList SEMI\n"); $$ = initParserNode("Def", yylineno); addParserDerivation($$, $1, $2, $3, NULL); cal_line($$); }
    | Specifier DecList error { printDerivation("Def -> Specifier DecList error\n"); printSyntaxError("Missing semicolon ';'", $2->line);}
    ;

DecList: Dec { printDerivation("DecList -> Dec\n"); $$ = initParserNode("DecList", yylineno); addParserDerivation($$, $1, NULL); cal_line($$); }
    | Dec COMMA DecList { printDerivation("DecList -> Dec COMMA DecList\n"); $$ = initParserNode("DecList", yylineno); addParserDerivation($$, $1, $2, $3, NULL); cal_line($$); }
    ;

Dec: VarDec { printDerivation("Dec -> VarDec\n"); $$ = initParserNode("Dec", yylineno); addParserDerivation($$, $1, NULL); cal_line($$); }
    | VarDec ASSIGN Exp { printDerivation("Dec -> VarDec ASSIGN Exp\n"); $$ = initParserNode("Dec", yylineno); addParserDerivation($$, $1, $2, $3, NULL); cal_line($$); }
    ;

Exp: Exp ASSIGN Exp { printDerivation("Exp -> Exp ASSIGN Exp\n"); $$ = initParserNode("Exp", yylineno); addParserDerivation($$, $1, $2, $3, NULL); cal_line($$); }
    | Exp OR Exp { printDerivation("Exp -> Exp OR Exp\n"); $$ = initParserNode("Exp", yylineno); addParserDerivation($$, $1, $2, $3, NULL); cal_line($$); }
    | Exp AND Exp { printDerivation("Exp -> Exp AND Exp\n"); $$ = initParserNode("Exp", yylineno); addParserDerivation($$, $1, $2, $3, NULL); cal_line($$); }
    | Exp EQ Exp { printDerivation("Exp -> Exp EQ Exp\n"); $$ = initParserNode("Exp", yylineno); addParserDerivation($$, $1, $2, $3, NULL); cal_line($$); }
    | Exp NEQ Exp { printDerivation("Exp -> Exp NEQ Exp\n"); $$ = initParserNode("Exp", yylineno); addParserDerivation($$, $1, $2, $3, NULL); cal_line($$); }
    | Exp LT Exp { printDerivation("Exp -> Exp LT Exp\n"); $$ = initParserNode("Exp", yylineno); addParserDerivation($$, $1, $2, $3, NULL); cal_line($$); }
    | Exp GT Exp { printDerivation("Exp -> Exp GT Exp\n"); $$ = initParserNode("Exp", yylineno); addParserDerivation($$, $1, $2, $3, NULL); cal_line($$); }
    | Exp LEQ Exp { printDerivation("Exp -> Exp LEQ Exp\n"); $$ = initParserNode("Exp", yylineno); addParserDerivation($$, $1, $2, $3, NULL); cal_line($$); }
    | Exp GEQ Exp { printDerivation("Exp -> Exp GEQ Exp\n"); $$ = initParserNode("Exp", yylineno); addParserDerivation($$, $1, $2, $3, NULL); cal_line($$); }
    | Exp PLUS Exp { printDerivation("Exp -> Exp PLUS Exp\n"); $$ = initParserNode("Exp", yylineno); addParserDerivation($$, $1, $2, $3, NULL); cal_line($$); }
    | Exp MINUS Exp { printDerivation("Exp -> Exp MINUS Exp\n"); $$ = initParserNode("Exp", yylineno); addParserDerivation($$, $1, $2, $3, NULL); cal_line($$); }
    | Exp MUL Exp { printDerivation("Exp -> Exp MUL Exp\n"); $$ = initParserNode("Exp", yylineno); addParserDerivation($$, $1, $2, $3, NULL); cal_line($$); }
    | Exp DIV Exp { printDerivation("Exp -> Exp DIV Exp\n"); $$ = initParserNode("Exp", yylineno); addParserDerivation($$, $1, $2, $3, NULL); cal_line($$); }
    | LP Exp RP { printDerivation("Exp -> LP Exp RP\n"); $$ = initParserNode("Exp", yylineno); addParserDerivation($$, $1, $2, $3, NULL); cal_line($$); }
    | LP error { printDerivation("Exp -> LP error\n"); printSyntaxError("Missing closing parenthesis ')'", (int)$1->line); }
    // | MINUS Exp %prec UMINUS 
    | MINUS Exp { printDerivation("Exp -> MINUS Exp\n"); $$ = initParserNode("Exp", yylineno); addParserDerivation($$, $1, $2, NULL); cal_line($$); }
    | NOT Exp { printDerivation("Exp -> NOT Exp\n"); $$ = initParserNode("Exp", yylineno); addParserDerivation($$, $1, $2, NULL); cal_line($$); }
    | ID LP Args RP { printDerivation("Exp -> ID LP Args RP\n"); $$ = initParserNode("Exp", yylineno); addParserDerivation($$, $1, $2, $3, $4, NULL); cal_line($$); }
    | ID LP RP { printDerivation("Exp -> ID LP RP\n"); $$ = initParserNode("Exp", yylineno); addParserDerivation($$, $1, $2, $3, NULL); cal_line($$); }
    | ID LP error { printDerivation("Exp -> ID LP error\n"); printSyntaxError("Missing closing parenthesis ')'", (int)$2->line); }
    | Exp LB Exp RB { printDerivation("Exp -> Exp LB Exp RB\n"); $$ = initParserNode("Exp", yylineno); addParserDerivation($$, $1, $2, $3, $4, NULL); cal_line($$); }
    | Exp DOT ID { printDerivation("Exp -> Exp DOT ID\n"); $$ = initParserNode("Exp", yylineno); addParserDerivation($$, $1, $2, $3, NULL); cal_line($$); }
    | ID { printDerivation("Exp -> ID\n"); $$ = initParserNode("Exp", yylineno); addParserDerivation($$, $1, NULL); cal_line($$); }
    | INT { printDerivation("Exp -> INT\n"); $$ = initParserNode("Exp", yylineno); addParserDerivation($$, $1, NULL); cal_line($$); }
    | FLOAT { printDerivation("Exp -> FLOAT\n"); $$ = initParserNode("Exp", yylineno); addParserDerivation($$, $1, NULL); cal_line($$); }
    | CHAR { printDerivation("Exp -> CHAR\n"); $$ = initParserNode("Exp", yylineno); addParserDerivation($$, $1, NULL); cal_line($$); }
    | LITERAL { printDerivation("Exp -> LITERAL\n"); $$ = initParserNode("Exp", yylineno); addParserDerivation($$, $1, NULL); cal_line($$); }
    ;

Args: Exp COMMA Args { printDerivation("Args -> Exp COMMA Args\n"); $$ = initParserNode("Args", yylineno); addParserDerivation($$, $1, $2, $3, NULL); cal_line($$); }
    | Exp { printDerivation("Args -> Exp\n"); $$ = initParserNode("Args", yylineno); addParserDerivation($$, $1, NULL); cal_line($$); }
    ;

%%

void yyerror(const char *s) {
    /* printf("Error type B at Line %d: %s\n", yylineno, s); */
    /* exit(0); */
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
