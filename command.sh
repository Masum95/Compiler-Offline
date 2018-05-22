flex -o LexAnalyzer.cpp Scanner.l
g++ LexAnalyzer.cpp -lfl -o LexAnalyzer.out
./LexAnalyzer.out input.txt
