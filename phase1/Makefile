CC=gcc
FLEX=flex
BISON=bison
PRINT_DERIVATION=false
PRINT_TOKEN=false
CFLAGS= 
ifeq ($(PRINT_DERIVATION), true)
	CFLAGS += -DPRINT_DERIVATION
endif
ifeq ($(PRINT_TOKEN), true)
	CFLAGS += -DPRINT_TOKEN
endif
.PHONY: 
	clean test
main:
	$(BISON) -d -t syntax.y -Wcounterexamples
	$(FLEX) lex.l 
	$(CC) syntax.tab.c -lfl -o bin/splc $(CFLAGS)
lex: main
	$(CC) lex.yy.c -lfl -o bin/lex -DLEX_ONLY
clean:
	@rm -f lex.yy.c syntax.tab.c syntax.tab.h *.out
test: main 
	@bin/splc test/test_1_r03.spl
debug: main
	$(CC) syntax.tab.c -lfl -o bin/splc $(CFLAGS) -g
	@gdb bin/splc -x gdb.init

