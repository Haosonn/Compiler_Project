SHELL := /bin/bash
CC=gcc
FLEX=flex
BISON=bison
PRINT_PARSER_TREE=false
PRINT_DERIVATION=false
PRINT_TOKEN=false
TEST_CASE=test-ex/test_include.spl
TEST_CASE_BASE=test/test_1_r
N=10
CFLAGS= 
ifeq ($(PRINT_PARSER_TREE), true)
	CFLAGS += -DPRINT_PARSER_TREE
endif
ifeq ($(PRINT_DERIVATION), true)
	CFLAGS += -DPRINT_DERIVATION
endif
ifeq ($(PRINT_TOKEN), true)
	CFLAGS += -DPRINT_TOKEN
endif
.PHONY: 
	clean test
main:
	mkdir -p bin
	$(BISON) -d -t syntax.y 
	$(FLEX) lex.l 
	$(CC) syntax.tab.c -lfl -o bin/splc $(CFLAGS)
difference:
	
lex: main
	$(CC) lex.yy.c -lfl -o bin/lex -DLEX_ONLY
clean:
	@rm -f lex.yy.c syntax.tab.c syntax.tab.h *.out

test: main 
	@bin/splc ${TEST_CASE} > ${TEST_CASE}.myout
	@diff ${TEST_CASE}.out ${TEST_CASE}.myout -u || true
test_case: main
	@bin/splc ${TEST_CASE_BASE}${N}.spl > ${TEST_CASE_BASE}${N}.spl.myout
	@diff ${TEST_CASE_BASE}${N}.out ${TEST_CASE_BASE}${N}.spl.myout -u || true


test_all: main
	@for file in test/*.spl; do \
		echo "Testing $$file"; \
		bin/splc $$file > $$file.myout; \
		diff $$(echo $${file:0:-3}out) $$file.myout > test/difference/$$(basename $$file).diff -u || true;\
	done

self_test: main
	@for file in test/self_test/*.spl; do \
		echo "Testing $$file"; \
		bin/splc $$file > $$file.myout; \
	done

test_extra: main
	@for file in test-ex/*.spl; do \
		echo "Testing $$file"; \
		bin/splc $$file > $$file.myout; \
	done

debug: main
	$(CC) syntax.tab.c -lfl -o bin/splc $(CFLAGS) -g
	@gdb bin/splc -x gdb.init

