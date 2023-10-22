CC=gcc
FLEX=flex
BISON=bison
PRINT_PARSER_TREE=true
PRINT_DERIVATION=false
PRINT_TOKEN=false
TEST_CASE=test_1_r03.spl
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
lex: main
	$(CC) lex.yy.c -lfl -o bin/lex -DLEX_ONLY
clean:
	@rm -f lex.yy.c syntax.tab.c syntax.tab.h *.out
test: main 
	@bin/splc test/${TEST_CASE}
debug: main
	$(CC) syntax.tab.c -lfl -o bin/splc $(CFLAGS) -g
	@gdb bin/splc -x gdb.init

