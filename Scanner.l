%option noyywrap

%{

#include<cstdio>
#include<cstdlib>
#include<cstring>
#include<string.h>
#include<algorithm>
#include<iostream>
#include "SymbolTable.h"
#include"y.tab.h"

extern SymbolTable *table;
void yyerror(char *);

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
ALPAHNUM [a-zA-Z0-9]
UCN (\\u[0-9a-fA-F]{4}|\\U[0-9a-fA-F]{8})

%x STRING
%x COMMENT

%%


{NEWLINE} {line_count++;}
{WHITESPACE} {}

"if"	{
			return IF;
		}
"for"	{
			return FOR;

		}
"do"	{
			return DO;
		}

"int"	{
			return INT;
		}

"float"	{
			return FLOAT;
		}

"void"	{
			return VOID;
		}
"switch"	{
			return SWITCH;
		}
"default"	{
			return DEFAULT;
		}
"else"	{
      return ELSE;
		}
"while"	{
      return WHILE;
		}
"break"	{
			return BREAK;
		}
"char"	{
		  return  CHAR;
		}

"double"	{
    	 return DOUBLE;
		}
"return"  {
			return RETURN;
		}
"case"	{
		return CASE;
		}
"continue" {
			return CONTINUE;
			}


"(" 	{
      return LPAREN;

		}

")" 	{
      return RPAREN;

		}
"{" 	{
      return LCURL;
    }

"}" 	{
      return RCURL;

		}
"[" 	{
      return LTHIRD;

		}



"\+"	|
"-" {
      SymbolInfo * s = new SymbolInfo(yytext, "ADDOP");
      yylval.symVal = s;
      return ADDOP;
		}

"&&" |
"||"	{
      SymbolInfo* s = new SymbolInfo(yytext, "LOGICOP");
			yylval.symVal = s;
			return LOGICOP;

		}

"\+\+"  {return INCOP;}

"--"	{
        return DECOP;
      }

","		{
        return COMMA;
      }


"="		{
			  return ASSIGNOP;
		}
"!"		{
  			return NOT;
		}

";"		{
        return SEMICOLON;
      }

"*"	|
"/" |
"%" 	{
      SymbolInfo* s = new SymbolInfo(yytext,"MULOP");
      yylval.symVal = s;
      return MULOP;
		}

"<"	|
">" |
"<=" |
">=" |
"==" |
"!="	{
      SymbolInfo* s = new SymbolInfo(yytext,"RELOP");
      yylval.symVal = s;
      return RELOP;

		}

{DIGIT}+ 	{

        SymbolInfo* s =new  SymbolInfo(yytext, "CONST_INT");
			  yylval.symVal= s;
			  return CONST_INT;
			}

"]" 	{
            return RTHIRD;

      }
{DIGIT}*(\.{DIGIT}+)(E[+-]?{DIGIT}+)?	{


        SymbolInfo* s =new  SymbolInfo(yytext, "CONST_FLOAT");
			  yylval.symVal= s;
			  return CONST_FLOAT;
			}



	/*char literal*/
'([^'\\]|\\['\"\\ntafrbv]|\\[0-7]{1,3}|\\[Xx][0-9a-fA-F]+|{UCN})'	 {

			string str(yytext+1);
			str = str.substr(0,str.size()-1);



      SymbolInfo* s =new  SymbolInfo(formatString(str).c_str(), "CONST_CHAR");
			yylval.symVal= s;
			return CONST_CHAR;

			}


	/* String literal */
	/* \n to be converted in single character */
	/* look at the \" in middle */



\"([^"\\\n]|\\(.|\r?\n))*\"	{

			string strn(yytext);
			for(ci = yytext;*ci!='\0';ci++)
			{
				if(*ci=='\n') line_count++;
			}
      SymbolInfo* s =new  SymbolInfo(formatString(strn).c_str(), "STRING");
			yylval.symVal= s;
			return STRING;

}
	/*Comment Single and multi-line */

<INITIAL>"/*"	{
			commentStart = yytext;
			BEGIN(COMMENT);
			}

<COMMENT>\*\/	{
			char* comment = strndup(commentStart, yytext + 2 - commentStart);
			for(ci = comment;*ci!='\0';ci++)
			{
				if(*ci=='\n') line_count++;
			}
			free(comment);
  			BEGIN(INITIAL);
			}

<COMMENT>.	{/* Do nothing */}


\/\/([^\\\n]|\\(.|\r?\n))*	{
      
		}





	/*VARIABLE*/

[a-zA-Z_][a-zA-Z0-9_]{0,31} {
      string str(yytext);
      SymbolInfo* s =new  SymbolInfo(str, "ID");
			yylval.symVal= s;
			return ID;
		}


{DIGIT}*(\.{DIGIT}*\..*)	{

    				error_count++;
    			}

([0-9]*\.?[0-9]*E[+-]?[0-9]*\.+[0-9])*	{

    				error_count++;
    			}

{DIGIT}+{ALPAHNUM}+	{
              				error_count++;
              			}


'.{2,}'	{
				error_count++;
		}

''	{
				error_count++;
		}

'([^'\\]|\\['\"\\ntafrbv]|\\[0-7]{1,3}|\\[Xx][0-9a-fA-F]+|{UCN})	{
				error_count++;

		}

<COMMENT><<EOF>> {
				error_count++;
        return 0;
		}



\"([^"\\\n]|\\(.|\r?\n))*	{
			error_count++;
			for(ci = yytext;*ci!='\0';ci++)
			{
				if(*ci=='\n') line_count++;
			}
}

<<EOF>> {return 0;}

%%
