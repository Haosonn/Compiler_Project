%{
    #define EXIT_OK 0
    #define EXIT_FAIL 1

    // global variables
    enum TOKENS {
        TOKEN_TYPE, TOKEN_ID, TOKEN_ASSIGN, TOKEN_SEMI, TOKEN_LITERAL, TOKEN_INT, TOKEN_FLOAT, TOKEN_COMMA, TOKEN_IF, TOKEN_ELSE, TOKEN_WHILE, TOKEN_RETURN, TOKEN_PLUS, TOKEN_MINUS, TOKEN_MUL, TOKEN_DIV, TOKEN_EQ, TOKEN_NEQ, TOKEN_LT, TOKEN_GT, TOKEN_LEQ, TOKEN_GEQ, TOKEN_LP, TOKEN_RP, TOKEN_LC, TOKEN_RC
    };
    enum TYPES {
        TYPE_INT, TYPE_FLOAT, TYPE_CHAR
    };
    void process_reserved(char *text);
    void print_token_info(int token, char *text);
%}
%option yylineno
letter [a-zA-Z]
letter_ {letter}|_
digit [0-9]
literal '.*'
reserved (int|char|float|return|if|else|while)
int {digit}+
identifier {letter_}({letter_}|{digit})*

%%
{reserved} { process_reserved(yytext); }
{literal} {}
{digit}({letter_}|{letter})+ {}
{identifier} { print_token_info(TOKEN_ID, yytext); } 
{int} { print_token_info(TOKEN_INT, yytext);}
\( { print_token_info(TOKEN_LP, NULL); }
\) { print_token_info(TOKEN_RP, NULL); }
\{ { print_token_info(TOKEN_LC, NULL); }
\} { print_token_info(TOKEN_RC, NULL); }
= { print_token_info(TOKEN_ASSIGN, NULL); }
; { print_token_info(TOKEN_SEMI, NULL); }
[\n] {}
[\t\r ]+ {/* does nothing when seeing white spaces except new line */ }
. { /* a final rule that matches when seeing any character but new line */ }
<<EOF>> { yyterminate(); }

%%

void process_reserved(char *text) {
    if (strcmp(text, "int") == 0 || strcmp(text, "float") == 0 || strcmp(text, "char") == 0) {
        print_token_info(TOKEN_TYPE, text);
    } else if (strcmp(text, "return") == 0) {
        print_token_info(TOKEN_RETURN, NULL);
    } else if (strcmp(text, "if") == 0) {
        print_token_info(TOKEN_IF, NULL);
    } else if (strcmp(text, "else") == 0) {
        print_token_info(TOKEN_ELSE, NULL);
    } else if (strcmp(text, "while") == 0) {
        print_token_info(TOKEN_WHILE, NULL);
    }
}

void print_token_info(int token, char *text) {
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
        case TOKEN_LC: printf("LC\n"); break;
        case TOKEN_RC: printf("RC\n"); break;
    }
}

int main(int argc, char **argv){
    char *file_path;
    if(argc < 2){
        fprintf(stderr, "Usage: %s <file_path>\n", argv[0]);
        return EXIT_FAIL;
    } else if(argc == 2){
        file_path = argv[1];
        if(!(yyin = fopen(file_path, "r"))){
            perror(argv[1]);
            return EXIT_FAIL;
        }
        yylex();
        return EXIT_OK;
    } else{
        fputs("Too many arguments! Expected: 2.\n", stderr);
        return EXIT_FAIL;
    }
}

