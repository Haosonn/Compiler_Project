'''
    #define ADD_DERIVATION_0(_name)\
        $$ = initParserNode(#_name, yylineno); \
        $$.empty_value = 1;
    #define ADD_DERIVATION_1(_name)\
        $$ = initParserNode(#_name, yylineno); \
        addParserDerivation($$, $1, NULL); \
        cal_line($$);
    #define ADD_DERIVATION_2(_name)\
        $$ = initParserNode(#_name, yylineno); \
        addParserDerivation($$, $1, $2, NULL); \
        cal_line($$);
    #define ADD_DERIVATION_3(_name)\
        $$ = initParserNode(#_name, yylineno); \
        addParserDerivation($$, $1, $2, $3, NULL); \
        cal_line($$);
    #define ADD_DERIVATION_4(_name)\
        $$ = initParserNode(#_name, yylineno); \
        addParserDerivation($$, $1, $2, $3, $4, NULL); \
        cal_line($$);
    #define ADD_DERIVATION_5(_name)\
        $$ = initParserNode(#_name, yylineno); \
        addParserDerivation($$, $1, $2, $3, $4, $5, NULL); \
        cal_line($$);
    #define ADD_DERIVATION_6(_name)\
        $$ = initParserNode(#_name, yylineno); \
        addParserDerivation($$, $1, $2, $3, $4, $5, $6, NULL); \
        cal_line($$);
    #define ADD_DERIVATION_7(_name)\
        $$ = initParserNode(#_name, yylineno); \
        addParserDerivation($$, $1, $2, $3, $4, $5, $6, $7, NULL); \
        cal_line($$);
    #define ADD_DERIVATION_8(_name)\
        $$ = initParserNode(#_name, yylineno); \
        addParserDerivation($$, $1, $2, $3, $4, $5, $6, $7, $8, NULL); \
        cal_line($$);
    #define ADD_DERIVATION_9(_name)\
        $$ = initParserNode(#_name, yylineno); \
        addParserDerivation($$, $1, $2, $3, $4, $5, $6, $7, $8, $9, NULL); \
        cal_line($$);
'''

import re
import argparse

def substitute_macros(input_file, output_file):
    with open(input_file, 'r') as f:
        content = f.read()

    for i in range(10):
        pattern = r'ADD_DERIVATION_{0}\("([^"]*)"\);'.format(i)
        replacement = r'$$ = initParserNode("\1", yylineno); '
        
        if i == 0:
            replacement += '$$->empty_value = 1; '
        elif i == 1:
            replacement += 'addParserDerivation($$, $1, NULL); '
        elif i == 2:
            replacement += 'addParserDerivation($$, $1, $2, NULL); '
        elif i == 3:
            replacement += 'addParserDerivation($$, $1, $2, $3, NULL); '
        elif i == 4:
            replacement += 'addParserDerivation($$, $1, $2, $3, $4, NULL); '
        elif i == 5:
            replacement += 'addParserDerivation($$, $1, $2, $3, $4, $5, NULL); '
        elif i == 6:
            replacement += 'addParserDerivation($$, $1, $2, $3, $4, $5, $6, NULL); '
        elif i == 7:
            replacement += 'addParserDerivation($$, $1, $2, $3, $4, $5, $6, $7, NULL); '
        elif i == 8:
            replacement += 'addParserDerivation($$, $1, $2, $3, $4, $5, $6, $7, $8, NULL); '
        elif i == 9:
            replacement += 'addParserDerivation($$, $1, $2, $3, $4, $5, $6, $7, $8, $9, NULL); '
        if i > 0:
            replacement += 'cal_line($$);'
        content = re.sub(pattern, replacement, content)
    with open(output_file, 'w') as f:
        f.write(content)

if __name__ == '__main__':
    input_file = 'syntax.y'
    output_file = 'syntax_generated.y'
    substitute_macros(input_file, output_file)