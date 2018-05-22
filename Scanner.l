%option noyywrap

%{

#include<cstdio>
#include<cstdlib>
#include<cstring>
#include<string.h>
#include<algorithm>
#include<iostream>
#include "SymbolTable.h"


int line_count=1;
int error_count = 0;
int i = 0;
char *ci;
char *tmp;
char ch[50];
char *commentStart;
char *stringStart;
FILE *logout;
FILE *tokenout;

SymbolTable s(10);
string replaceString(string src,string match,string tbr)
{
    size_t index = 0;
    while (true)
    {
        index = src.find(match, index);
        if (index == std::string::npos) break;

        src.replace(index, match.size(), tbr);

        index += tbr.size();
    }
    return src;
}

string formatString(string str){
	
	str = replaceString(str,"\\n","\n");
	str = replaceString(str,"\\t","\t");
	str = replaceString(str,"\\\\","\\");
	str = replaceString(str,"\\f","\f");
	str = replaceString(str,"\\'","\'");
	str = replaceString(str,"\\a","\a");
	str = replaceString(str,"\\r","\r");
	str = replaceString(str,"\\b","\b");
	str = replaceString(str,"\\v","\v");
	str = replaceString(str,"\\0","");
	return str;
	
}

%}
WHITESPACE [ \t\f\r\v]+ 
LETTER [a-zA-Z]
DIGIT [0-9]
NEWLINE \n
ALPAHNUM [a-zA-z0-9]
UCN (\\u[0-9a-fA-F]{4}|\\U[0-9a-fA-F]{8})

%x STRING
%x COMMENT

%%


{NEWLINE} {line_count++;}
{WHITESPACE} {}

"if"	{
			fprintf(tokenout,"<IF>");
			printf("Line no %d: TOKEN <IF> Lexeme %s found\n",line_count,yytext);
		
		}
"for"	{
			fprintf(tokenout,"<FOR>");
			printf("Line no %d: TOKEN <FOR> Lexeme %s found\n",line_count,yytext);
		
		}
"do"	{
			fprintf(tokenout,"<DO>");
			printf("Line no %d: TOKEN <DO> Lexeme %s found\n",line_count,yytext);
		
		}
		
		
		
"int"	{
			fprintf(tokenout,"<INT>");
			printf("Line no %d: TOKEN <INT> Lexeme %s found\n",line_count,yytext);
		
		}
		
"float"	{
			fprintf(tokenout,"<FLOAT>");
			printf("Line no %d: TOKEN <FLOAT> Lexeme %s found\n",line_count,yytext);
		
		}
		
"void"	{
			fprintf(tokenout,"<VOID>");
			printf("Line no %d: TOKEN <VOID> Lexeme %s found\n",line_count,yytext);
		
		}
"switch"	{
			fprintf(tokenout,"<SWITCH>");
			printf("Line no %d: TOKEN <SWITCH> Lexeme %s found\n",line_count,yytext);
		
		}
"default"	{
			fprintf(tokenout,"<DEFAULT>");
			printf("Line no %d: TOKEN <DEFAULT> Lexeme %s found\n",line_count,yytext);
		
		}
"else"	{
			fprintf(tokenout,"<ELSE>");
			printf("Line no %d: TOKEN <ELSE> Lexeme %s found\n",line_count,yytext);
		}
"while"	{
			fprintf(tokenout,"<WHILE>");
			printf("Line no %d: TOKEN <WHILE> Lexeme %s found\n",line_count,yytext);
		
		}
"break"	{
			fprintf(tokenout,"<BREAK>");
			printf("Line no %d: TOKEN <BREAK> Lexeme %s found\n",line_count,yytext);
		
		}
"char"	{
			fprintf(tokenout,"<CHAR>");
			printf("Line no %d: TOKEN <CHAR> Lexeme %s found\n",line_count,yytext);
		
		}
		
"double"	{
			fprintf(tokenout,"<DOUBLE>");
			printf("Line no %d: TOKEN <DOUBLE> Lexeme %s found\n",line_count,yytext);
		
		}
"return"  {
			fprintf(tokenout,"<RETURN>");
			printf("Line no %d: TOKEN <RETURN> Lexeme %s found\n",line_count,yytext);
		
		}
"case"	{
			fprintf(tokenout,"<CASE>");
			printf("Line no %d: TOKEN <BREACASEK> Lexeme %s found\n",line_count,yytext);
		
		}
"continue" {
			fprintf(tokenout,"<CONTINUE>");
			printf("Line no %d: TOKEN <CONTINUE> Lexeme %s found\n",line_count,yytext);
		
			}
		

"(" 	{	 
			fprintf(tokenout,"<LPAREN,%s>",yytext);
			printf("Line no %d: TOKEN <LPAREN> Lexeme %s found\n",line_count,yytext);
		}

")" 	{	 
			fprintf(tokenout,"<RPAREN,%s>",yytext);
			printf("Line no %d: TOKEN <RPAREN> Lexeme %s found\n",line_count,yytext);
		}
"{" 	{	 
			fprintf(tokenout,"<LCURL,%s>",yytext);
			printf("Line no %d: TOKEN <LCURL> Lexeme %s found\n",line_count,yytext);
		}

"}" 	{	 
			fprintf(tokenout,"<RCURL,%s>",yytext);
			printf("Line no %d: TOKEN <RCURL> Lexeme %s found\n",line_count,yytext);
		}
"[" 	{	 
			fprintf(tokenout,"<LTHIRD,%s>",yytext);
			printf("Line no %d: TOKEN <LTHIRD> Lexeme %s found\n",line_count,yytext);
		}

"]" 	{	 
			fprintf(tokenout,"<RTHIRD,%s>",yytext);
			printf("Line no %d: TOKEN <RTHIRD> Lexeme %s found\n",line_count,yytext);
		}

"\+"	| 
"-" {
			fprintf(tokenout,"<ADDOP,%s>",yytext);
			printf("Line no %d: TOKEN <ADDOP> Lexeme %s found\n",line_count,yytext);
			
		}
		
"&&" |
"||"	{
			fprintf(tokenout,"<LOGICOP,%s>",yytext);
			printf("Line no %d: TOKEN <LOGICOP> Lexeme %s found\n",line_count,yytext);
		}
		
"\+\+" |
"--"	{
			fprintf(tokenout,"<INCOP,%s>",yytext);
			printf("Line no %d: TOKEN <INCOP> Lexeme %s found\n",line_count,yytext);
		}

","		{
			fprintf(tokenout,"<COMMA,%s>",yytext);
			printf("Line no %d: TOKEN <COMMA> Lexeme %s found\n",line_count,yytext);
		}
		
		
"="		{
			fprintf(tokenout,"<ASSIGNOP,%s>",yytext);
			printf("Line no %d: TOKEN <ASSIGNOP> Lexeme %s found\n",line_count,yytext);
			
		}
"!"		{
			fprintf(tokenout,"<NOT,%s>",yytext);
			printf("Line no %d: TOKEN <NOT> Lexeme %s found\n",line_count,yytext);
			
		}
		
";"		{
			fprintf(tokenout,"<SEMICOLON,%s>",yytext);
			printf("Line no %d: TOKEN <SEMICOLON> Lexeme %s found\n",line_count,yytext);
		}
		
"*"	| 
"/" |
"%" 	{
			fprintf(tokenout,"<MULOP,%s>",yytext);
			printf("Line no %d: TOKEN <MULOP> Lexeme %s found\n",line_count,yytext);
		}
		
"<"	|
">" |
"<=" |
">=" |
"==" |
"!="	{
			fprintf(tokenout,"<RELOP,%s>",yytext);
			printf("Line no %d: TOKEN <RELOP> Lexeme %s found\n",line_count,yytext);
		}
		
{DIGIT}+ 	{
				fprintf(tokenout,"<CONST_INT,%s>",yytext);
				printf("Line no %d: TOKEN <CONST_INT> Lexeme %s found\n",line_count,yytext);
				
				strcpy(ch,"I ");
				strcat(ch,yytext);
				strcat(ch," CONST_INT");
			
				s.executeCommand(ch);
				strcpy(ch,"P A");
				s.executeCommand(ch);				
			}
			
{DIGIT}*(\.{DIGIT}+)(E[+-]?{DIGIT}+)?	{
				fprintf(tokenout,"<CONST_FLOAT,%s>",yytext);
				printf("Line no %d: TOKEN <CONST_FLOAT> Lexeme %s \n",line_count,yytext);

				strcpy(ch,"I ");
				strcat(ch,yytext);
				strcat(ch," CONST_FLOAT");
			
				s.executeCommand(ch);
				strcpy(ch,"P A");
				s.executeCommand(ch);			
			}
			


	/*char literal*/
'([^'\\]|\\['\"\\ntafrbv]|\\[0-7]{1,3}|\\[Xx][0-9a-fA-F]+|{UCN})'	 {
			
			string str(yytext+1);
			str = str.substr(0,str.size()-1);
			fprintf(tokenout,"%s",formatString(str).c_str());
			printf("Line no %d: TOKEN <CONST_CHAR> Lexeme %s found\n",line_count,yytext);
			
			strcpy(ch,"I ");
			strcat(ch,yytext);
			strcat(ch," CONST_CHAR");
			
			s.executeCommand(ch);
			strcpy(ch,"P A");
			s.executeCommand(ch);		
			
			}
 
 
	/* String literal */
	/* \n to be converted in single character */
	/* look at the \" in middle */



\"([^"\\\n]|\\(.|\r?\n))*\"	{

			string strn(yytext);
			cout<<strn<<endl;
			fprintf(tokenout,"<STRING,%s>",formatString(strn).c_str());
			printf("Line no %d: TOKEN <STRING> Lexeme %s found\n",line_count,yytext);
			for(ci = yytext;*ci!='\0';ci++)
			{
				if(*ci=='\n') line_count++;
			}
}
	/*Comment Single and multi-line */

<INITIAL>"/*"	{
			commentStart = yytext;
			BEGIN(COMMENT);
			}
			
<COMMENT>\*\/	{
			char* comment = strndup(commentStart, yytext + 2 - commentStart);
			fprintf(tokenout,"<COMMENT>");
			printf("Line no %d: TOKEN <COMMENT> Lexeme %s found\n",line_count,comment);
			for(ci = comment;*ci!='\0';ci++)
			{
				if(*ci=='\n') line_count++;
			}
			free(comment); 
  			BEGIN(INITIAL); 
			}

<COMMENT>.	{/* Do nothing */}




\/\/([^\\\n]|\\(.|\r?\n))*	{
			fprintf(tokenout,"<COMMENT>");
			printf("Line no %d: TOKEN <COMMENT> Lexeme %s found\n",line_count,yytext);
			
		}
		
		



	/*VARIABLE*/
	
[a-zA-Z_][a-zA-Z0-9_]{0,31} {
			fprintf(tokenout,"<ID,%s>",yytext);
			printf("Line no %d: TOKEN <ID> Lexeme %s found\n",line_count,yytext);
			
			strcpy(ch,"I ");
			strcat(ch,yytext);
			strcat(ch," ID");
			
			s.executeCommand(ch);
			strcpy(ch,"P A");
			s.executeCommand(ch);
		}


{DIGIT}*(\.{DIGIT}*\..*)	{
			
				printf("Error at line %d: Too many decimal point %s \n",line_count,yytext);
				error_count++;
			}
			
([0-9]*\.?[0-9]*E[+-]?[0-9]*\.+[0-9])*	{
			
				printf("Error at line %d: Ill formed number %s \n",line_count,yytext);
				error_count++;
			}

{DIGIT}+{ALPAHNUM}+	{
				printf("Error at line %d: Invalid prefix on ID or invalid suffix on Number %s \n",line_count,yytext);
				error_count++;
			}


'.{2,}'	{
				printf("Error at line %d: Multi character constant error %s \n",line_count,yytext);
				error_count++;
		
		}
		
''	{
				printf("Error at line %d: Empty character constant error %s \n",line_count,yytext);
				error_count++;
		
		}

'([^'\\]|\\['\"\\ntafrbv]|\\[0-7]{1,3}|\\[Xx][0-9a-fA-F]+|{UCN})	{
				printf("Error at line %d: Unterminated character %s \n",line_count,yytext);
				error_count++;
		
		}
		
<COMMENT><<EOF>> {
				char* str = strndup(commentStart, yytext + 2 - commentStart);
				printf("Error at line %d: Unfinished comment %s \n",line_count,str);
				error_count++;
				free(str);
				return 0;
		}



\"([^"\\\n]|\\(.|\r?\n))*	{
			printf("Error at line %d: Unfinished comment %s \n",line_count,yytext);
			error_count++;
			for(ci = yytext;*ci!='\0';ci++)
			{
				if(*ci=='\n') line_count++;
			}
}

<<EOF>> {return 0;}

%%

int main(int argc,char *argv[]){
	
	if(argc!=2){
		printf("Please provide input file name and try again\n");
		return 0;
	}
	
	FILE *fin=fopen(argv[1],"r");
	if(fin==NULL){
		printf("Cannot open specified file\n");
		return 0;
	}
	
	freopen("log.txt","w",stdout);
	tokenout= fopen("token.txt","w");

	yyin= fin;
	yylex();
	fclose(yyin);
	fclose(tokenout);
	printf("\n");
	printf("Total lines %d\n",line_count-1);
	printf("Total Errors %d\n",error_count);
	
	return 0;
}