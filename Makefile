SHELL := /bin/bash
CC=gcc
FLEX=flex
BISON=bison

PRINT_PARSER_TREE=false
PRINT_DERIVATION=false
PRINT_TOKEN=false
PRINT_SYMBOL_TABLE=false

TEST_CASE=test_phase2/test_1.spl
TEST_CASE_BASE=test_phase2_ex/test_
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

.PHONY: 
	clean test
main:
	mkdir -p bin
	$(BISON) -d -t syntax.y 
	$(FLEX) lex.l 
	$(CC) syntax.tab.c $(SRC) -lfl -o bin/splc $(CFLAGS)
difference:
	
lex: main
	$(CC) lex.yy.c -lfl -o bin/lex -DLEX_ONLY
clean:
	@rm -f lex.yy.c syntax.tab.c syntax.tab.h *.out
	@rm -f test/*.out test-ex/*.out

test: main
	@for file in test/*.spl; do \
		echo "Testing $$file"; \
		bin/splc $$file > $$(dirname $$file)/$$(basename $$file .spl).out; \
	done

test_extra: main
	@for file in test-ex/*.spl; do \
		echo "Testing $$file"; \
		bin/splc $$file > $$(dirname $$file)/$$(basename $$file .spl).out; \
	done

