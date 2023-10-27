%{
    #include "syntax.tab.h"
    #include "parser_node.h"
    #include "string_map.h"

    #define EXIT_OK 0
    #define EXIT_FAIL 1
    #define PROCESS_TOKEN(_token) \
        switch(_token) { \
            case TOKEN_TYPE: yylval.parser_node = initParserNode("TYPE", yylineno); yylval.parser_node->value.string_value = malloc(sizeof(char) * (strlen(yytext) + 1)); strcpy(yylval.parser_node->value.string_value, yytext); return TYPE; \
            case TOKEN_STRUCT: yylval.parser_node = initParserNode("STRUCT", yylineno); return STRUCT; \
            case TOKEN_ID: yylval.parser_node = initParserNode("ID", yylineno); yylval.parser_node->value.string_value = malloc(sizeof(char) * (strlen(yytext) + 1)); strcpy(yylval.parser_node->value.string_value, yytext); return ID; \
            case TOKEN_ASSIGN: yylval.parser_node = initParserNode("ASSIGN", yylineno); return ASSIGN; \
            case TOKEN_SEMI: yylval.parser_node = initParserNode("SEMI", yylineno); return SEMI; \
            case TOKEN_LITERAL: yylval.parser_node = initParserNode("LITERAL", yylineno); yylval.parser_node->value.string_value = malloc(sizeof(char) * (strlen(yytext) + 1)); strcpy(yylval.parser_node->value.string_value, yytext); return LITERAL; \
            case TOKEN_INT: yylval.parser_node = initParserNode("INT", yylineno); yylval.parser_node->value.int_value = atoi(yytext); return INT; \
            case TOKEN_HEXINT: yylval.parser_node = initParserNode("INT", yylineno); yylval.parser_node->value.int_value = hexstr_to_int(yytext); return INT; \
            case TOKEN_FLOAT: yylval.parser_node = initParserNode("FLOAT", yylineno); yylval.parser_node->value.float_value = atof(yytext); return FLOAT; \
            case TOKEN_CHAR: yylval.parser_node = initParserNode("CHAR", yylineno); yylval.parser_node->value.string_value = malloc(sizeof(char) * (strlen(yytext) + 1)); strcpy(yylval.parser_node->value.string_value, yytext); return CHAR; \
            case TOKEN_COMMA: yylval.parser_node = initParserNode("COMMA", yylineno); return COMMA; \
            case TOKEN_IF: yylval.parser_node = initParserNode("IF", yylineno); return IF; \
            case TOKEN_ELSE: yylval.parser_node = initParserNode("ELSE", yylineno); return ELSE; \
            case TOKEN_WHILE: yylval.parser_node = initParserNode("WHILE", yylineno); return WHILE; \
            case TOKEN_FOR: yylval.parser_node = initParserNode("FOR", yylineno); return FOR; \
            case TOKEN_RETURN: yylval.parser_node = initParserNode("RETURN", yylineno); return RETURN; \
            case TOKEN_PLUS: yylval.parser_node = initParserNode("PLUS", yylineno); return PLUS; \
            case TOKEN_MINUS: yylval.parser_node = initParserNode("MINUS", yylineno); return MINUS; \
            case TOKEN_MUL: yylval.parser_node = initParserNode("MUL", yylineno); return MUL; \
            case TOKEN_DIV: yylval.parser_node = initParserNode("DIV", yylineno); return DIV; \
            case TOKEN_EQ: yylval.parser_node = initParserNode("EQ", yylineno); return EQ; \
            case TOKEN_NEQ: yylval.parser_node = initParserNode("NEQ", yylineno); return NEQ; \
            case TOKEN_LT: yylval.parser_node = initParserNode("LT", yylineno); return LT; \
            case TOKEN_GT: yylval.parser_node = initParserNode("GT", yylineno); return GT; \
            case TOKEN_LEQ: yylval.parser_node = initParserNode("LEQ", yylineno); return LEQ; \
            case TOKEN_GEQ: yylval.parser_node = initParserNode("GEQ", yylineno); return GEQ; \
            case TOKEN_LP: yylval.parser_node = initParserNode("LP", yylineno); return LP; \
            case TOKEN_RP: yylval.parser_node = initParserNode("RP", yylineno); return RP; \
            case TOKEN_LB: yylval.parser_node = initParserNode("LB", yylineno); return LB; \
            case TOKEN_RB: yylval.parser_node = initParserNode("RB", yylineno); return RB; \
            case TOKEN_LC: yylval.parser_node = initParserNode("LC", yylineno); return LC; \
            case TOKEN_RC: yylval.parser_node = initParserNode("RC", yylineno); return RC; \
            case TOKEN_AND: yylval.parser_node = initParserNode("AND", yylineno); return AND; \
            case TOKEN_OR: yylval.parser_node = initParserNode("OR", yylineno); return OR; \
            case TOKEN_DOT: yylval.parser_node = initParserNode("DOT", yylineno); return DOT; \
        }
    #define PROCESS_TOKEN_AND_PRINT(_token) \
        int token = print_token_info(_token, yytext); \
        PROCESS_TOKEN(token);

    // global variables
    enum TOKENS {
        TOKEN_TYPE,
        TOKEN_STRUCT,
        TOKEN_ID, 
        TOKEN_ASSIGN, 
        TOKEN_SEMI, 
        TOKEN_LITERAL, 
        TOKEN_INT, 
        TOKEN_HEXINT,
        TOKEN_FLOAT,
        TOKEN_CHAR, 
        TOKEN_COMMA, 
        TOKEN_IF, 
        TOKEN_ELSE, 
        TOKEN_WHILE, 
        TOKEN_FOR,
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
    int hexstr_to_int(char *hexstr);

    void process_inclusion(char *text);
    void process_define(char *text);
    void replace_macro(char *text);

    struct Map *define_map;

%}
%option yylineno
letter [a-zA-Z]
letter_ {letter}|_
digit [0-9]
non_zero_digit [1-9]
hex_digit [a-fA-F]
reserved (int|char|float|struct|return|if|else|while|for)
int ({non_zero_digit}{digit}*)|0
hex_int 0(x|X)(0|({non_zero_digit}|({hex_digit})({digit}|{hex_digit})*))
float {digit}+"."{digit}+
char (\'.\')|(\'\\(x|X)({digit}|{hex_digit})({digit}|{hex_digit})?\')
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
{identifier} { PROCESS_TOKEN_AND_PRINT(TOKEN_ID) } 
{int} { PROCESS_TOKEN_AND_PRINT(TOKEN_INT) }
{hex_int} { PROCESS_TOKEN_AND_PRINT(TOKEN_HEXINT) }
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
"+" { PROCESS_TOKEN_AND_PRINT(TOKEN_PLUS) }
"-" { PROCESS_TOKEN_AND_PRINT(TOKEN_MINUS) }
"*" { PROCESS_TOKEN_AND_PRINT(TOKEN_MUL) }
"/" { PROCESS_TOKEN_AND_PRINT(TOKEN_DIV) }

#include[ ]+\"[^\"]*\" { process_inclusion(yytext); }


"//".* { yycolno = 1; }
"/*"(.|\n)*?"*/" { yycolno = 1; }

[\n] { yycolno = 1; }
[\t\r ]+ {/* does nothing when seeing white spaces except new line */ }
. { 
    printf("Lexical error at line %d: Unknown symbol %s\n", yylineno, yytext);
 }
<<EOF>> { 
    yypop_buffer_state();
    if (!YY_CURRENT_BUFFER) {
        yyterminate();
    }
 }

%%

int process_reserved(char *text) {
    if (strcmp(text, "int") == 0 || strcmp(text, "float") == 0 || strcmp(text, "char") == 0) {
        print_token_info(TOKEN_TYPE, text);
        return TOKEN_TYPE;
    } else if (strcmp(text, "struct") == 0) {
        print_token_info(TOKEN_STRUCT, NULL);
        return TOKEN_STRUCT;
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
    } else if (strcmp(text, "for") == 0) {
        print_token_info(TOKEN_FOR, NULL);
        return TOKEN_FOR;
    }
}

int print_token_info(int token, char *text) {
    
#ifndef PRINT_TOKEN
    return token;
#endif

    printf("lexeme: ");
    switch(token) {
        case TOKEN_TYPE: 
            printf("TYPE ");
            printf("%s\n", text); 
            break;
        case TOKEN_STRUCT: printf("STRUCT\n"); break;
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
        case TOKEN_FOR: printf("FOR\n"); break;
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

int hexstr_to_int(char *hexstr) {
    int result = (int)strtol(hexstr + 2, NULL, 16);
    return result;
}

void process_inclusion(char *text) {
    // get the file path
    int file_name_start = 0, file_name_end = 0;
    int i = 0;
    while(file_name_end == 0) {
        if (text[i] == '\"') {
            if (file_name_start == 0) {
                file_name_start = i + 1;
            } else {
                file_name_end = i;
            }
        }
        i++;
    }
    extern char* source_path;
    char *addr = (char *) malloc(strlen(source_path) + strlen(text) + 1);
    strcpy(addr, source_path);
    char *last_slash = strrchr(addr, '/');
    if(last_slash) {
        *(last_slash + 1) = '\0';
    } else {
        addr[0] = '\0';
    }
    strcat(addr, text + file_name_start);
    addr[strlen(addr) - 1] = '\0'; // remove the last " in the string
    // printf("process source path: %s\n", addr);
    yyin = fopen(addr, "r");
    yypush_buffer_state(yy_create_buffer(yyin, YY_BUF_SIZE));
    free(addr);
    BEGIN(INITIAL);
    return;
}

void process_define(char *text) {
    // get the macro name
    int start = 0;
    int end = 0;
    int i = 0;
    while(end == 0) {
        if (text[i] == ' ') {
            if (start == 0) {
                start = i + 1;
            } else {
                end = i;
            }
        }
        i++;
    }
    char *macro_name = malloc(sizeof(char) * (end - start));
    strncpy(macro_name, text + start, end - start);

    printf("macro name: %s\n", macro_name);

    // get the macro value
    start = end + 1;
    end = 0;
    i = start;
    while(end == 0) {
        if (text[i] == '\n') {
            end = i;
        }
        i++;
    }
    char *macro_value = malloc(sizeof(char) * (end - start));
    strncpy(macro_value, text + start, end - start);

    printf("macro value: %s\n", macro_value);
    
    if(!define_map) {
        /* initMap(define_map); */
    }
    /* setMap(define_map, macro_name, macro_value); */
}

void replace_macro(char *text) {
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

