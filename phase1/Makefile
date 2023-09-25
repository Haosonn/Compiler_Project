CC=gcc
FLEX=flex
main:
	$(FLEX) lexer.l 
	$(CC) lex.yy.c -lfl -o lexer.out
clean:
	@rm -f lexer.yy.c *.out
test:
	@./lexer.out ../sample_code/phase1/3-4.spl 