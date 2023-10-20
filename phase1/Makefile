CC=gcc
FLEX=flex
BISON=bison
.PHONY: 
	clean test
main:
	$(BISON) -d syntax.y -Wcounterexamples
	$(FLEX) lex.l 
	$(CC) syntax.tab.c -lfl -o bin/splc 
lex: main
	$(CC) lex.yy.c -lfl -o bin/lex -DLEX_ONLY
clean:
	@rm -f lex.yy.c syntax.tab.c syntax.tab.h *.out
test: main 
	@bin/splc test/test_1_r03.spl
