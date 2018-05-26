

bison -d -y -v Parser.y
echo '1'
g++ -w -c -o yacc.o y.tab.c
echo '2'
flex -o LexAnalyzer.cpp Scanner.l
echo '3'
g++ -w -c -o lex.o lex.yy.c
# if the above command doesn't work try g++ -fpermissive -w -c -o l.o lex.yy.c
echo '4'
g++ -o a.out yacc.o lex.o -lfl -ly
echo '5'
./a.out input.txt
