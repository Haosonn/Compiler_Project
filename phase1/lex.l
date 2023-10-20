%{
    #include "syntax.tab.h"
    /* library inclusions */


    #define EXIT_OK 0
    #define EXIT_FAIL 1
    #define PROCESS_TOKEN(_token) \
        switch(_token) { \
            case TOKEN_TYPE: return TYPE; \
            case TOKEN_ID: return ID; \
            case TOKEN_ASSIGN: return ASSIGN; \
            case TOKEN_SEMI: return SEMI; \
            case TOKEN_LITERAL: return LITERAL; \
            case TOKEN_INT: return INT; \
            case TOKEN_FLOAT: return FLOAT; \
            case TOKEN_CHAR: return CHAR; \
            case TOKEN_COMMA: return COMMA; \
            case TOKEN_IF: return IF; \
            case TOKEN_ELSE: return ELSE; \
            case TOKEN_WHILE: return WHILE; \
            case TOKEN_RETURN: return RETURN; \
            case TOKEN_PLUS: return PLUS; \
            case TOKEN_MINUS: return MINUS; \
            case TOKEN_MUL: return MUL; \
            case TOKEN_DIV: return DIV; \
            case TOKEN_EQ: return EQ; \
            case TOKEN_NEQ: return NEQ; \
            case TOKEN_LT: return LT; \
            case TOKEN_GT: return GT; \
            case TOKEN_LEQ: return LEQ; \
            case TOKEN_GEQ: return GEQ; \
            case TOKEN_LP: return LP; \
            case TOKEN_RP: return RP; \
            case TOKEN_LB: return LB; \
            case TOKEN_RB: return RB; \
            case TOKEN_LC: return LC; \
            case TOKEN_RC: return RC; \
            case TOKEN_AND: return AND; \
            case TOKEN_OR: return OR; \
            case TOKEN_DOT: return DOT; \
        }
    #define PROCESS_TOKEN_AND_PRINT(_token) \
        int token = print_token_info(_token, yytext); \
        PROCESS_TOKEN(token);

    // global variables
    enum TOKENS {
        TOKEN_TYPE,
        TOKEN_ID, 
        TOKEN_ASSIGN, 
        TOKEN_SEMI, 
        TOKEN_LITERAL, 
        TOKEN_INT, 
        TOKEN_FLOAT,
        TOKEN_CHAR, 
        TOKEN_COMMA, 
        TOKEN_IF, 
        TOKEN_ELSE, 
        TOKEN_WHILE, 
        TOKEN_RETURN, 
        TOKEN_PLUS, 
        TOKEN_MINUS, 
        TOKEN_MUL, 
        TOKEN_DIV, 
        TOKEN_EQ, 
        TOKEN_NEQ, 
        TOKEN_LT, 
        TOKEN_GT, 
        TOKEN_LEQ, 
        TOKEN_GEQ, 
        TOKEN_LP, 
        TOKEN_RP, 
        TOKEN_LB, 
        TOKEN_RB, 
        TOKEN_LC, 
        TOKEN_RC, 
        TOKEN_AND, 
        TOKEN_OR,
        TOKEN_DOT
    };
    enum TYPES {
        TYPE_INT, TYPE_FLOAT, TYPE_CHAR
    };
    int yycolno = 1;
    int process_reserved(char *text);
    int print_token_info(int token, char *text);
%}
%option yylineno
letter [a-zA-Z]
letter_ {letter}|_
digit [0-9]
reserved (int|char|float|return|if|else|while)
int {digit}+
float {digit}+"."{digit}+
char \'.\'
identifier {letter_}({letter_}|{digit})*


%%
\"[^\"]*\" {
    if(yytext[yyleng-2] == '\\') {
        yyless(yyleng-1);
        yymore();
    } else {
        PROCESS_TOKEN(TOKEN_LITERAL)
    }
}
{reserved} { 
    int token = process_reserved(yytext); 
    PROCESS_TOKEN(token)
}
{digit}({letter_}|{letter})+ {}
{identifier} { PROCESS_TOKEN_AND_PRINT(TOKEN_ID) } 
{int} { PROCESS_TOKEN_AND_PRINT(TOKEN_INT) }
{float} { PROCESS_TOKEN_AND_PRINT(TOKEN_FLOAT) }
{char} { PROCESS_TOKEN_AND_PRINT(TOKEN_CHAR) }
"," { PROCESS_TOKEN_AND_PRINT(TOKEN_COMMA) }
"(" { PROCESS_TOKEN_AND_PRINT(TOKEN_LP) }
")" { PROCESS_TOKEN_AND_PRINT(TOKEN_RP) }
"[" { PROCESS_TOKEN_AND_PRINT(TOKEN_LB) }
"]" { PROCESS_TOKEN_AND_PRINT(TOKEN_RB) }
"{" { PROCESS_TOKEN_AND_PRINT(TOKEN_LC) }
"}" { PROCESS_TOKEN_AND_PRINT(TOKEN_RC) }
"=" { PROCESS_TOKEN_AND_PRINT(TOKEN_ASSIGN) }
"<" { PROCESS_TOKEN_AND_PRINT(TOKEN_LT) }
">" { PROCESS_TOKEN_AND_PRINT(TOKEN_GT) }
"<=" { PROCESS_TOKEN_AND_PRINT(TOKEN_LEQ) }
">=" { PROCESS_TOKEN_AND_PRINT(TOKEN_GEQ) }
"==" { PROCESS_TOKEN_AND_PRINT(TOKEN_EQ) }
"!=" { PROCESS_TOKEN_AND_PRINT(TOKEN_NEQ) }
";" { PROCESS_TOKEN_AND_PRINT(TOKEN_SEMI) }
"&&" { PROCESS_TOKEN_AND_PRINT(TOKEN_AND) }
"||" { PROCESS_TOKEN_AND_PRINT(TOKEN_OR) }
"." { PROCESS_TOKEN_AND_PRINT(TOKEN_DOT) }

[\n] { yycolno = 1; }
[\t\r ]+ {/* does nothing when seeing white spaces except new line */ }
. { 
    printf("Lexical error at line %d: Unknown symbol %s\n", yylineno, yytext);
 }
<<EOF>> { yyterminate(); }

%%

int process_reserved(char *text) {
    if (strcmp(text, "int") == 0 || strcmp(text, "float") == 0 || strcmp(text, "char") == 0) {
        print_token_info(TOKEN_TYPE, text);
        return TOKEN_TYPE;
    } else if (strcmp(text, "return") == 0) {
        print_token_info(TOKEN_RETURN, NULL);
        return TOKEN_RETURN;
    } else if (strcmp(text, "if") == 0) {
        print_token_info(TOKEN_IF, NULL);
        return TOKEN_IF;
    } else if (strcmp(text, "else") == 0) {
        print_token_info(TOKEN_ELSE, NULL);
        return TOKEN_ELSE;
    } else if (strcmp(text, "while") == 0) {
        print_token_info(TOKEN_WHILE, NULL);
        return TOKEN_WHILE;
    }
}

int print_token_info(int token, char *text) {
    /* return token; */
    printf("lexeme: ");
    switch(token) {
        case TOKEN_TYPE: 
            printf("TYPE ");
            printf("%s\n", text); 
            break;
        case TOKEN_ID: 
            printf("ID "); 
            printf("%s\n", text);
            break;
        case TOKEN_ASSIGN: printf("ASSIGN\n"); break;
        case TOKEN_SEMI: printf("SEMI\n"); break;
        case TOKEN_LITERAL: 
            printf("LITERAL "); 
            printf("%s\n", text);
            break;
        case TOKEN_INT: 
            printf("INT "); 
            printf("%s\n", text);
            break;
        case TOKEN_FLOAT: 
            printf("FLOAT "); 
            printf("%s\n", text);
            break;
        case TOKEN_CHAR:
            printf("CHAR ");
            printf("%s\n", text);
            break;
        case TOKEN_COMMA: printf("COMMA\n"); break;
        case TOKEN_IF: printf("IF\n"); break;
        case TOKEN_ELSE: printf("ELSE\n"); break;
        case TOKEN_WHILE: printf("WHILE\n"); break;
        case TOKEN_RETURN: printf("RETURN\n"); break;
        case TOKEN_PLUS: printf("PLUS\n"); break;
        case TOKEN_MINUS: printf("MINUS\n"); break;
        case TOKEN_MUL: printf("MUL\n"); break;
        case TOKEN_DIV: printf("DIV\n"); break;
        case TOKEN_EQ: printf("EQ\n"); break;
        case TOKEN_NEQ: printf("NEQ\n"); break;
        case TOKEN_LT: printf("LT\n"); break;
        case TOKEN_GT: printf("GT\n"); break;
        case TOKEN_LEQ: printf("LEQ\n"); break;
        case TOKEN_GEQ: printf("GEQ\n"); break;
        case TOKEN_LP: printf("LP\n"); break;
        case TOKEN_RP: printf("RP\n"); break;
        case TOKEN_LB: printf("LB\n"); break;
        case TOKEN_RB: printf("RB\n"); break;
        case TOKEN_LC: printf("LC\n"); break;
        case TOKEN_RC: printf("RC\n"); break;
    }
    return token;
}

#ifdef LEX_ONLY
int main(int argc, char **argv) {
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
        yylex();
        return EXIT_SUCCESS;
    } else {
        fputs("Too many arguments! Expected: 2.\n", stderr);
        return EXIT_FAILURE;
    }
}
#endif
