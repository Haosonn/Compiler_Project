SHELL := /bin/bash
CC=gcc
FLEX=flex
BISON=bison
PRINT_PARSER_TREE=true
PRINT_DERIVATION=false
PRINT_TOKEN=false
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
	
clean:
	@rm -f lex.yy.c syntax.tab.c syntax.tab.h *.out

test_all: main
	@for file in test/*.spl; do \
		echo "Testing $$file"; \
		bin/splc $$file > $${file:0:-3}out; \
	done

test_extra: main
	@for file in test-ex/*.spl; do \
		echo "Testing $$file"; \
		bin/splc $$file > $${file:0:-3}out; \
	done
