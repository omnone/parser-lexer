compile: lex.yy.c parser.tab.c
	gcc  lex.yy.c parser.tab.c -o program -lfl

run: program
	./program ${file}

lex.yy.c: parser.tab.c lexer.l
	flex lexer.l

parser.tab.c: parser.y
	bison  -d parser.y

clean: 
	rm -f lex.yy.c parser.tab.c parser.tab.h run