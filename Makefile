SHELL := /bin/bash
CC=gcc
FLEX=flex
BISON=bison
PYTHON=python3

PRINT_PARSER_TREE=false
PRINT_DERIVATION=false
PRINT_TOKEN=false
PRINT_SYMBOL_TABLE=false
PRINT_IR=true

TEST_CASE=test_phase2/test_1.spl
TEST_CASE_BASE=test_phase2/test_2_s
N=scope

CFLAGS=-Iinclude 
SRC=src/*.c

ifeq ($(PRINT_PARSER_TREE), true)
	CFLAGS += -DPRINT_PARSER_TREE
endif
ifeq ($(PRINT_DERIVATION), true)
	CFLAGS += -DPRINT_DERIVATION
endif
ifeq ($(PRINT_TOKEN), true)
	CFLAGS += -DPRINT_TOKEN
endif
ifeq ($(PRINT_SYMBOL_TABLE), true)
	CFLAGS += -DPRINT_SYMBOL_TABLE
endif
ifeq ($(PRINT_IR), true)
	CFLAGS += -DPRINT_IR
endif

.PHONY: 
	clean test
main:
	mkdir -p bin
	$(PYTHON) syntax_generator.py
	$(BISON) -d -t syntax_generated.y 
	$(FLEX) lex.l 
	$(CC) syntax_generated.tab.c $(SRC) -lfl -o bin/splc $(CFLAGS)
	
lex: main
	$(CC) lex.yy.c -lfl -o bin/lex -DLEX_ONLY
clean:
	@rm -f lex.yy.c syntax.tab.c syntax.tab.h *.out 

test_case: main
	@bin/splc ${TEST_CASE_BASE}${N}.spl > ${TEST_CASE_BASE}${N}.spl.myout
	# @diff ${TEST_CASE_BASE}${N}.out ${TEST_CASE_BASE}${N}.spl.myout -u || true

test_all: main
	@for file in test_phase3/*.spl; do \
		echo "Testing $$file"; \
		bin/splc $$file > $$(dirname $$file)/$$(basename $$file .spl).ir; \
	done

test_ir_1: test_all
	./irsim test_phase3/test_3_r01.ir -i 101; \
	./irsim test_phase3/test_3_r01.ir -i 10
test_ir_2: test_all
	./irsim test_phase3/test_3_r02.ir -i 5,2; \
	./irsim test_phase3/test_3_r02.ir -i 9,7
test_ir_3: test_all
	./irsim test_phase3/test_3_r03.ir
test_ir_4: test_all
	./irsim test_phase3/test_3_r04.ir -i 30
test_ir_5: test_all
	./irsim test_phase3/test_3_r05.ir -i 10
test_ir_6: test_all
	./irsim test_phase3/test_3_r06.ir
test_ir_array: test_all
	./irsim test_phase3/array.ir
test_ir_struct: test_all
	./irsim test_phase3/struct.ir

debug: 
	$(PYTHON) syntax_generator.py
	$(BISON) -d -t syntax_generated.y 
	$(FLEX) lex.l 
	$(CC) syntax_generated.tab.c $(SRC) -lfl -o bin/splc $(CFLAGS) -g

