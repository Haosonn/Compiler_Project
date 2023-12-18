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
		bin/splc $$file > $$file.myout; \
	done

self_test: main
	@for file in test_phase3/self_test/*.spl; do \
		echo "Testing $$file"; \
		bin/splc $$file > $$file.myout; \
	done

test_extra: main
	@for file in test_phase2_ex/*.spl; do \
		echo "Testing $$file"; \
		bin/splc $$file > $$file.myout; \
	done

debug: 
	$(PYTHON) syntax_generator.py
	$(BISON) -d -t syntax_generated.y 
	$(FLEX) lex.l 
	$(CC) syntax_generated.tab.c $(SRC) -lfl -o bin/splc $(CFLAGS) -g

