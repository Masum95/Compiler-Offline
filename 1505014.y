%{
	#include<iostream>
	#include<cstdlib>
	#include<cstring>
	#include<string>
	#include<algorithm>
	#include<cmath>
	#include<set>
	#include "SymbolTable.h"
	//#define YYSTYPE SymbolInfo*

	using namespace std;
	struct Array{
		string name;
		string siz;
		Array(){name = "";}
		Array(string name,string siz){ this->name = name , this->siz = siz;}
	};
	int yyparse(void);
	int yylex(void);
	extern FILE *yyin;
	extern int line_count;
	FILE *fp;
	ofstream logFile, errorFile, asmFile , optimizedFile;

	int syntaxError = 0;
	int semError = 0;
	string variable_type;
	string FuncRetVar = "rv";
	int paramNum = 1;
	bool isMain = 0 , post = 0;
	set<string> asmParamOut;
	set<string> asmParamIn;
	vector<SymbolInfo*> params;
	vector<string> args;
	vector<string> variables;
	vector<Array> arrays;

	int argsWithId = 0;

	SymbolTable table(11);


	void yyerror(const char *s)
	{
		printf("%s\n",s);
	}

	string compareToZero(string var)
	{
		return "\tmov ax , " + var +"\n"  +
		"\tcmp ax , 0\n";
	}

	string intToString(int a)
	{
		string tmp = "";
		while(a!=0)
		{
			tmp+= (a%10) + '0';
			a/=10;
		}
		reverse(tmp.begin(),tmp.end());
		return tmp;
	}

	string initFunc(bool parInOut)
	{
		string str = "\tpush ax\n\tpush bx\n\tpush cx\n\tpush dx\n ";
		if(parInOut)
		{
			for(int i=1;i<=4;i++)
			{
				str+= "\tpush parIn"+intToString(i)+"\n";
			}
			for(int i=1;i<=4;i++)
			{
				str+= "\tmov ax,parOut"+intToString(i)+"\n";
				str+= "\tmov parIn"+intToString(i)+",ax\n";
			}
		}

		str+= "\n";
		return str;
	}

	string endFunc(bool parInOut)
	{
		string str = "\n";
		if(parInOut)
		{
			for(int i=4;i>=1;i--)
			{
				str+= "\tpop parIn"+intToString(i)+"\n";
			}
		}

		str+= "\tpop dx\n\tpop cx\n\tpop bx\n\tpop ax\n";
		return str;
	}

	vector<string> stringSplit(string str){
		stringstream ssin(str);
		string line;
		vector<string> tmp;
		while(getline(ssin, line))
		{

			std::size_t prev = 0, pos;
			while ((pos = line.find_first_of(" ,", prev)) != std::string::npos)
			{

				if (pos > prev)
				tmp.push_back(line.substr(prev, pos-prev));
				prev = pos+1;
			}
			if (prev < line.length())
			tmp.push_back(line.substr(prev, std::string::npos));
		}
		return tmp;
	}
	string optimization(string code){
		vector<string> tokens;
		stringstream ss(code);
		string token,retString;
		while(getline(ss,token,'\n')){
			tokens.push_back(token);
		}
		retString += tokens[0];
		for(int i=1;i<tokens.size();i++){
			vector<string> prevString = stringSplit(tokens[i-1]);
			vector<string> curString = stringSplit(tokens[i]);

			if(prevString.size()>1 && curString.size()>1)
			{
				if(prevString[0]=="mov" && curString[0]=="mov"){
					if(prevString[1]==curString[2] && prevString[2]==curString[1]) continue;

				}
			}
			retString+= "\n" +tokens[i];

		}
		return retString + "\n";
	}

	string setParameter(vector<string> &vc)
	{
		string tmp ;
		for(int i=0;i<vc.size();i++)  // assuming 4 parameter
		{
			tmp+= "\tmov ax," + vc[i] + "\n";
			tmp+= "\tmov parOut"  +intToString(i+1)+", ax\n";
		}
		return tmp;
	}
	int labelCount = 1, tempCount = 0 , maxTemp = 0;
	string newLabel()
	{
		char* lb= new char[4];
		strcpy(lb,"L");
		char b[3];
		sprintf(b,"%d", labelCount);
		labelCount++;
		strcat(lb,b);
		return string(lb);
	}

	string newTemp()
	{
		char* t= new char[4];
		strcpy(t,"t");
		char b[3];
		sprintf(b,"%d", tempCount);
		tempCount++;
		if(maxTemp  < tempCount) maxTemp = tempCount;
		strcat(t,b);
		return string(t);
	}

	%}

	%union{
		SymbolInfo *symVal;
	}

	%token COMMENT IF ELSE FOR WHILE DO BREAK CONTINUE INT FLOAT CHAR DOUBLE VOID RETURN SWITCH CASE DEFAULT INCOP DECOP ASSIGNOP LPAREN RPAREN LCURL RCURL LTHIRD RTHIRD SEMICOLON COMMA STRING NOT PRINTLN
	%token <symVal>ID
	%token <symVal>CONST_INT
	%token <symVal>CONST_FLOAT
	%token <symVal>CONST_CHAR
	%token <symVal>ADDOP
	%token <symVal>MULOP
	%token <symVal>LOGICOP
	%token <symVal>RELOP


	%type <symVal> start type_specifier expression logic_expression rel_expression simple_expression term unary_expression factor variable argument_list arguments var_declaration func_declaration func_definition parameter_list compound_statement declaration_list statements statement expression_statement program unit

	%nonassoc second_precedence
	%nonassoc ELSE
	%error-verbose

	%%

	start : program
	{
		$$ = $1;
		$$->code+="\n\nDECIMAL_OUT PROC NEAR\n\n" +initFunc(0)+ "\tor ax,ax\n \tjge enddif\n\tpush ax\n\tmov dl,'-'\n\tmov ah,2\n\tint 21h\n\tpop ax\n\tneg ax\nenddif:\n\txor cx,cx\n\tmov bx,10d\nrepeat:\n\txor dx,dx\n\tdiv bx\n\t push dx\n\tinc cx\n\tor ax,ax\n\tjne repeat\n\tmov ah,2\nprint_loop:\n\tpop dx\n\tor dl,30h\n\tint 21h\n\tloop print_loop\n" +endFunc(0)+  "\tret\n\nDECIMAL_OUT ENDP\n";

		if(semError==0)
		{
			asmFile<<".model small\n.stack 100h\n.data\n";
			optimizedFile<<".model small\n.stack 100h\n.data\n";
			for(int i = 0; i<variables.size() ; i++){
				asmFile << variables[i] << " dw ?\n";
				optimizedFile << variables[i] << " dw ?\n";
			}
			asmFile  << "rv dw ?\n";
			optimizedFile  << "rv dw ?\n";
			for(int i=1;i<=4;i++)
			{
				asmFile << "parIn"+intToString(i)+" dw ?\n";
					optimizedFile << "parIn"+intToString(i)+" dw ?\n";
			}
			for(int i=1;i<=4;i++)
			{
				asmFile << "parOut"+intToString(i)+" dw ?\n";
				optimizedFile << "parOut"+intToString(i)+" dw ?\n";
			}
			for(int i = 0 ; i< arrays.size() ; i++){
				asmFile << arrays[i].name << " dw " << arrays[i].siz << " dup(?)\n";
				optimizedFile << arrays[i].name << " dw " << arrays[i].siz << " dup(?)\n";
			}

			asmFile << "\n.code \n";
			optimizedFile << "\n.code \n";
			asmFile<<$$->code;
			optimizedFile<<optimization($$->code);
			asmFile<<"end main\n";
			optimizedFile<<"end main\n";
		}
	}
	;

	program : program unit
	{

		$1->stmt = $1->stmt + "\n\n" + $2->stmt;
		$$ = $1;
		$$->code += $2->code;

	}
	| unit
	{

		$$ = $1;

	}
	;

	unit : 	var_declaration
	{

		$$ = $1;

	}
	|
	func_declaration
	{

		$$ = $1;

	}
	|
	func_definition
	{

		$$ = $1;

	}
	;

	func_declaration : type_specifier ID LPAREN parameter_list RPAREN SEMICOLON
	{
		string exp = $1->stmt + " " + $2->getName() + "(" + $4->stmt + ");";

		SymbolInfo *asgn = (new SymbolInfo());
		asgn->stmt = exp;
		$$ = asgn;



		SymbolInfo* isDeclared = table.lookUpInScopes((new SymbolInfo())->setName($2->getName())->setIDType( "FUNC") );
		if(isDeclared!=NULL && isDeclared->funcDeclared==true)
		{
			logFile <<  "Error at line " << line_count << " Function "<< $2->getName() <<" already declared" << endl << endl;
			semError++;
		}

		else{
			SymbolInfo *tmp = new SymbolInfo();
			tmp->setName($2->getName())->setType("ID")->setIDType("FUNC")->setFuncRetType($1->getVarType());
			// Parameter List to be Inserted
			for(int i=0;i<args.size();i++)
			{
				tmp->ParamList.push_back(args[i]);
			}
			tmp->funcDeclared = true;
			if(isDeclared==NULL) table.insert(tmp);
			argsWithId = 0;
			args.clear();params.clear();paramNum = 1;
		}

	}
	|type_specifier ID LPAREN parameter_list RPAREN error
	{
		logFile <<  "Error at line " << line_count << " ; missing" << endl << endl;
		semError++;
	}
	;

	func_definition : type_specifier ID LPAREN parameter_list RPAREN
	{
		SymbolInfo *tmp = table.lookUpInScopes((new SymbolInfo())->setName($2->getName())->setIDType("FUNC"));
		if($2->getName()=="main") isMain = 1;

		if(argsWithId!=args.size())
		{
			logFile <<  "Error at line " << line_count << " Parameter mismatch for Function "<< $2->getName() << endl << endl;
			semError++;
		}
		else{
			if(tmp==NULL)
			{
				SymbolInfo *tmp2 = new SymbolInfo();
				tmp2->setName($2->getName())->setType("ID")->setIDType("FUNC")->setFuncRetType($1->getVarType());
				// Parameter List to be Inserted

				for(int i=0;i<args.size();i++)
				{
					tmp2->ParamList.push_back(args[i]);
					//
				}
				table.insert(tmp2);
			}
			else{

				if(tmp->isFuncDefined()){
					logFile <<  "Error at line " << line_count << "Function "<< $2->getName() <<" already defined" << endl << endl;
					semError++;

				}

				else if(tmp->getFuncRetType() != $1->getVarType()){
					logFile <<  "Error at line " << line_count << ": Function "<< $2->getName() <<" :return type doesn't match declaration" << endl << endl;
					semError++;

				}
				else if (tmp->ParamList.size()!=argsWithId )
				{
					logFile <<  "Error at line " << line_count << "Function "<< $2->getName() <<" :Parameter list does not match declaration" << endl << endl;
					semError++;
				}
				else{
					for(int i = 0; i<tmp->ParamList.size(); i++){
						if(tmp->ParamList[i] != args[i]){
							logFile <<  "Error at line " << line_count << "Function "<< $2->getName()<< " :argument mismatch" << endl << endl;
							semError++;
						}
					}
				}

			}
		}
		args.clear();
		argsWithId = 0;
		paramNum = 1;

		} compound_statement{


			string exp = $1->stmt + " " + $2->getName() + "(" + $4->stmt + ")\n" + $7->stmt;
			SymbolInfo *asgn = (new SymbolInfo());
			asgn->stmt = exp;
			$$ = asgn;

			$$ = new SymbolInfo();
			$$->code+= "\n\n";
			if($2->getName()=="main")
			{
				$$->code = $2->getName() + " proc\n";
				$$->code+= "\tmov ax,@data\n\tmov ds,ax\n";
				$$->code+= $7->code;
				$$->code+= "\tmov ah,4ch \n\tint 21h\n";
				$$->code+=  $2->getName() + " endp\n";
				isMain = 0;
			}
			else{
				$$->code = $2->getName() + " proc\n";
				$$->code+= initFunc(1);
				$$->code+= $7->code;
				$$->code+=  $2->getName() + " endp\n";
			}
			$$->code+= "\n\n";
		}
		;

		parameter_list  : parameter_list COMMA type_specifier ID
		{


			string exp = $1->stmt+ "," + $3->stmt + " " + $4->getName();
			SymbolInfo *asgn = new SymbolInfo();
			asgn->stmt = exp;
			$$ = asgn;


			argsWithId++;
			args.push_back(variable_type);
			SymbolInfo *tmp = new SymbolInfo();
			tmp->setIDType("VAR")->setType("ID")->setVarType(variable_type)->setName($4->getName());
			tmp->icgName = "parIn"+intToString(paramNum);
			asmParamOut.insert("parOut"+intToString(paramNum));
			paramNum++;
			params.push_back(tmp);
		}
		| parameter_list COMMA type_specifier
		{


			args.push_back(variable_type);

			string exp = $1->stmt+ "," + $3->stmt;
			SymbolInfo *asgn = new SymbolInfo();
			asgn->stmt = exp;
			$$ = asgn;

		}
		| type_specifier ID
		{

			argsWithId++;
			args.push_back(variable_type);
			SymbolInfo *tmp = new SymbolInfo();
			tmp->setIDType("VAR")->setType("ID")->setVarType(variable_type)->setName($2->getName());
			tmp->icgName = "parIn"+intToString(paramNum);
			asmParamOut.insert("parOut"+intToString(paramNum));
			paramNum++;
			params.push_back(tmp);

			string exp = $1->stmt + " " + $2->getName();
			SymbolInfo *asgn = new SymbolInfo();
			asgn->stmt = exp;
			$$ = asgn;

		}
		| type_specifier
		{

			args.push_back(variable_type);

			SymbolInfo *asgn = new SymbolInfo();
			asgn->stmt = $1->stmt;
			$$ = asgn;


		}
		| /*EMPTY */
		{
			SymbolInfo *asgn = new SymbolInfo();
			asgn->stmt = "";
			$$ = asgn;
		}
		;


		compound_statement : LCURL {
			table.enterScope();

			for(int i=0;i<params.size();i++)
			{
				table.insert(params[i]);
			}
			params.clear();
			} statements {

				} RCURL {

					$$ = $3;;

					table.exitScope();
				}
				| LCURL RCURL { logFile << "At line no: "<< line_count << " : compound_statement : LCURL RCURL\n"<< endl;  }
				;


				var_declaration : type_specifier declaration_list SEMICOLON {
					string exp = $1->stmt +  " "+ $2->stmt+";";


					SymbolInfo *tmp = new SymbolInfo();
					tmp->stmt = exp;
					$$ = tmp;
				}
				|type_specifier declaration_list error
				{
					logFile <<  "Error at line " << line_count << "Inappropriate declaration" << endl << endl;
					semError++;
				}
				;

				type_specifier	: INT
				{

					SymbolInfo* tmp= new SymbolInfo();
					tmp->setVarType("INT");
					tmp->stmt = "int";
					variable_type = "INT";
					$$ = tmp;
				}
				| FLOAT
				{

					SymbolInfo* tmp= new SymbolInfo();
					tmp->setVarType("FLOAT");
					tmp->stmt = "float";
					variable_type = "FLOAT";
					$$ = tmp;
				}
				| VOID
				{

					SymbolInfo* tmp= new SymbolInfo();
					tmp->setVarType("VOID");
					tmp->stmt = "void";
					variable_type = "VOID";
					$$ = tmp;
				}
				;

				declaration_list : declaration_list COMMA ID
				{

					$$ = $1;
					if(variable_type == "VOID"){
						errorFile << "Error at line " << line_count << " :variable type can't be void" << endl << endl;
						semError++;
					}
					else{
						SymbolInfo *tmp = table.lookUpInCurScope((new SymbolInfo())->setName($3->getName())->setIDType("VAR"));
						SymbolInfo *tmp3 = table.lookUpInCurScope((new SymbolInfo())->setName($3->getName())->setIDType("ARA"));
						//Is it declared earlier as different or same idType ?
						if(tmp==NULL && tmp3==NULL)
						{
							SymbolInfo* tmp2 = new SymbolInfo();
							tmp2->setName($3->getName())->setIDType("VAR")->setVarType(variable_type)->setType("ID");
							tmp2->icgName = $3->getName()+intToString(table.scopeNumShow);
							table.insert(tmp2);
						}
						else{
							errorFile << "Error at line " << line_count << ": Variable "<< $3->getName() <<" already declared" << endl << endl;
							semError++;
						}
						$$ = $1;

						variables.push_back($3->getName()+intToString(table.scopeNumShow));
					}
				}
				| declaration_list COMMA ID LTHIRD CONST_INT RTHIRD
				{
					//$1->stmt = $1->stmt +  ","+ $3->getName() +"[" + $5->getName() + "]";
					$$ = $1 ;
					logFile << $$->stmt << endl << endl;

					if(variable_type == "VOID"){
						errorFile << "Error at line " << line_count << " : array type can't be void" << endl << endl;
						semError++;
					}
					else{
						SymbolInfo *tmp = table.lookUpInCurScope((new SymbolInfo())->setName($3->getName())->setIDType("ARA"));
						SymbolInfo *tmp3 = table.lookUpInCurScope((new SymbolInfo())->setName($3->getName())->setIDType("VAR"));
						if(tmp!=NULL || tmp3!=NULL)
						{
							errorFile << "Error at line " << line_count << ": Variable "<< $3->getName() <<" already declared" << endl << endl;
							semError++;
						}
						else{

							SymbolInfo *tmp2 = new SymbolInfo();
							tmp2->setName($3->getName())->setIDType("ARA")->setVarType(variable_type);
							int sz = atoi($5->getName().c_str());
							tmp2->setAraSize(sz);
							tmp2->icgName = $3->getName()+intToString(table.scopeNumShow);
							tmp2->stmt = $1->stmt + "," +$3->getName() + "[" + $5->getName() + "]";

							table.insert(tmp2);
							arrays.push_back(Array($3->getName()+intToString(table.scopeNumShow),$5->getName()));


						}
					}
				}
				| ID
				{
					SymbolInfo *asgn = new SymbolInfo();
					asgn->stmt = $1->getName();
					$$ = asgn;
					logFile << $$->stmt << endl << endl;

					if(variable_type == "VOID"){
						errorFile << "Error at line " << line_count << " :variable type can't be void" << endl << endl;
						semError++;
					}
					else{
						SymbolInfo *tmp = table.lookUpInCurScope((new SymbolInfo())->setName($1->getName())->setIDType("VAR"));
						SymbolInfo *tmp3 = table.lookUpInCurScope((new SymbolInfo())->setName($1->getName())->setIDType("ARA"));
						//Is it declared earlier as different or same idType ?

						if(tmp==NULL && tmp3==NULL)
						{
							SymbolInfo* tmp2 = new SymbolInfo();
							tmp2->setName($1->getName())->setIDType("VAR")->setVarType(variable_type)->setType("ID");
							tmp2->icgName = $1->getName()+intToString(table.scopeNumShow);
							table.insert(tmp2);
						}
						else{
							errorFile << "Error at line " << line_count << ": Multiple Declaration of "<<$1->getName() << endl << endl;
							semError++;
						}

						variables.push_back($1->getName()+intToString(table.scopeNumShow));

					}
				}
				| ID LTHIRD CONST_INT RTHIRD
				{

					logFile << "At line no: "<< line_count << " : declaration_list :	ID LTHIRD CONST_INT RTHIRD\n"<<endl;

					SymbolInfo *asgn = new SymbolInfo();
					asgn->stmt = $1->getName() + "[" + $3->getName() + "]";
					$$ = asgn;
					logFile << $$->stmt << endl << endl;

					if(variable_type == "VOID"){
						errorFile << "Error at line " << line_count << " : array type can't be void" << endl << endl;
						semError++;
					}
					else{
						SymbolInfo *tmp = table.lookUpInCurScope((new SymbolInfo())->setName($3->getName())->setIDType("ARA"));
						SymbolInfo *tmp3 = table.lookUpInCurScope((new SymbolInfo())->setName($3->getName())->setIDType("VAR"));
						if(tmp!=NULL || tmp3!=NULL)
						{
							errorFile << "Error at line " << line_count << ": Multiple Declaration of "<<$1->getName() << endl << endl;
							semError++;
						}
						else{
							SymbolInfo *tmp2 = new SymbolInfo();
							tmp2->setName($1->getName())->setIDType("ARA")->setVarType(variable_type)->setType("ID");
							int sz = atoi($3->getName().c_str());
							tmp2->setAraSize(sz);

							tmp2->icgName = $1->getName()+intToString(table.scopeNumShow);
							table.insert(tmp2);

						}
					}
					arrays.push_back(Array($1->getName()+intToString(table.scopeNumShow),$3->getName()));

				}
				;

				statements : statement{ $$ = $1;}
				| statements statement{
					$2->stmt = $1->stmt + "\n" + $2->stmt;
					$$ = new SymbolInfo();
					$$->code = $1->code + $2->code;

				}
				;


				statement : var_declaration{ $$ = $1;}
				| expression_statement{ $$ = $1;
				}
				| compound_statement{$$ = $1;}
				| FOR LPAREN expression_statement expression_statement expression RPAREN statement
				{

					$$ = new SymbolInfo();
					$$->code = $3->code;
					string label1 = newLabel();
					string label2 = newLabel();
					$$->code += label1 + ":\n";
					$$->code+=$4->code;
					$$->code+="\tmov ax , "+$4->icgName+"\n";
					$$->code+="\tcmp ax , 0\n";
					$$->code+="\tje "+label2+"\n";
					$$->code+=$7->code;
					$$->code+=$5->code;
					$$->code+="\tjmp "+label1+"\n";
					$$->code+=label2+":\n";

					//delete $4; delete $5; delete $7;

				}
				| IF LPAREN expression RPAREN statement  %prec second_precedence
				{

					$$ = new SymbolInfo();
					string exitlabel = newLabel();
					$$->code = $3->code;
					$$->code+= compareToZero($3->icgName);
					$$->code+= "\tje " + exitlabel + "\n";
					$$->code+= $5->code;
					$$->code+=exitlabel + ":\n";

				}
				| IF LPAREN expression RPAREN statement ELSE statement
				{


					$$ = new SymbolInfo();
					string exitLabel = newLabel();
					string elselabel = newLabel();
					$$->code = $3->code;
					$$->code+= compareToZero($3->icgName);
					$$->code+= "\tje " + elselabel + "\n";
					$$->code+= $5->code;
					$$->code+= "\tjmp "+ exitLabel + "\n";
					$$->code+= elselabel + ":\n";
					$$->code+= $7->code;
					$$->code+=exitLabel + ":\n";

					//delete $3; delete $5; delete $7;

				}
				| WHILE LPAREN expression RPAREN statement{

					$$ = new SymbolInfo();
					string  label = newLabel();
					string  exit = newLabel();
					$$->code = label + ":\n";
					$$->code+=$3->code;
					$$->code+= compareToZero($3->icgName);
					$$->code+="\tje "+exit+"\n";

					$$->code+=$5->code;
					$$->code+="\tjmp "+label+"\n";
					$$->code+=exit+":\n";

				}
				| PRINTLN LPAREN ID RPAREN SEMICOLON{
					$$ = new SymbolInfo();
					SymbolInfo *cur = table.lookUpInCurScope((new SymbolInfo())->setName($3->getName())->setIDType("VAR"));
					SymbolInfo *tmp = table.lookUpInScopes((new SymbolInfo())->setName($3->getName())->setIDType("VAR"));
					if(cur==NULL && tmp==NULL)
					{
						errorFile << "Error at line " << line_count << " : Undeclared Variable" << endl << endl;
						semError++;
					}
					else if(cur==NULL) cur = tmp;
					if(cur!=NULL)
					{
						$$->code += "\tmov ax, " + cur->icgName +"\n";
						$$->code += "\tcall DECIMAL_OUT\n";
					}


					//TBMF
				}
				| PRINTLN LPAREN ID RPAREN error
				{
					logFile <<  "Error at line " << line_count << "; missing" << endl << endl;
					semError++;
				}
				| RETURN expression SEMICOLON{

					$$ = (new SymbolInfo())->copyObject($2);
					if(!isMain)
					{
						$$->code = $2->code;
						$$->code+="\tmov dx,"+$2->icgName+"\n"; // return in dx register
						$$->code+="\tmov "+FuncRetVar +",dx\n";
						$$->code+=endFunc(1);
						$$->code+="ret\n";
					}

				}
				|RETURN expression error
				{
					logFile <<  "Error at line " << line_count << "; missing" << endl << endl;
					semError++;
				}
				;

				expression_statement 	: SEMICOLON{

				}
				| expression SEMICOLON {

					$$ = (new SymbolInfo())->copyObject($1); $$->code = $1->code;
					$$->stmt = $1->stmt + ";" ;
				}
				|expression error
				{
					logFile <<  "Error at line " << line_count << "; missing" << endl << endl;
					semError++;
				}
				;


				expression : logic_expression
				{

					$$ = (new SymbolInfo())->copyObject($1); $$->code = $1->code;

				}
				| variable ASSIGNOP logic_expression
				{

					$$= new SymbolInfo();

					if($1->getIDType()!="ARA")
					{
						$$->code=$3->code+$1->code;
						$$->code+= "\tmov ax," + $3->icgName+"\n";
						$$->code+= "\tmov "+$1->icgName+", ax\n";
					}
					else {

						$$->code = $3->code;

						$$->code+= $1->getIndex();

						$$->code+= "\tmov ax," + $3->icgName+"\n";
						$$->code+= "\tmov  "+$1->writeData+"[bx], ax\n";

					}
					//delete $3;
					//-----------Table to be printed ----
				}
				;

				logic_expression : rel_expression
				{

					$$ = (new SymbolInfo())->copyObject($1); $$->code = $1->code;

					//TBMF
				}
				| rel_expression LOGICOP rel_expression
				{
					$$ = new SymbolInfo();
					$$->code =$1->code+$3->code;
					string  label1 = newLabel();
					string  label2 = newLabel();
					string  temp = newTemp();
					variables.push_back(temp);
					//question-> newPTemp or newTemp           ????????
					//question-> temp to be declared first     ???????
					if($2->getName()=="&&"){
						/*
						Check whether both operands value is 1. If both are one set value of a temporary variable to 1
						otherwise 0
						*/
						$$->code += compareToZero($1->icgName);
						$$->code += "\tje " + label1 +"\n";
						$$->code += compareToZero($3->icgName);
						$$->code += "\tje " + label1 +"\n";
						$$->code += "\tmov " + temp + " , 1\n";
						$$->code += "\tjmp " + label2 + "\n";
						$$->code += label1 + ":\n" ;
						$$->code += "\tmov " + temp + ", 0\n";
						$$->code += label2 + ":\n";

					}
					else if($2->getName()=="||"){
						$$->code += compareToZero($1->icgName);
						$$->code += "\tjne " + label1 +"\n";
						$$->code += compareToZero($3->icgName);
						$$->code += "\tjne " + label1 +"\n";
						$$->code += "\tmov " + temp + " , 0\n";
						$$->code += "\tjmp " + label2 + "\n";
						$$->code += label1 + ":\n" ;
						$$->code += "\tmov " + temp + ", 1\n";
						$$->code += label2 + ":\n";

					}
					$$->icgName = temp;
					//delete $3;
					$$->stmt = $1->stmt + " " + $2->getName() + " " + $3->stmt;

				}
				;

				rel_expression	: simple_expression
				{

					$$ = (new SymbolInfo())->copyObject($1); $$->code = $1->code;

				}
				| simple_expression RELOP simple_expression
				{
					string relop = $2->getName();
					int ans;
					$$ = new SymbolInfo();
					$$->code=$1->code;
					$$->code+=$3->code;
					$$->code+="\tmov ax, " + $1->icgName+"\n";
					$$->code+="\tcmp ax, " + $3->icgName+"\n";
					string temp=newTemp();
					variables.push_back(temp);
					//question-> newPTemp or newTemp           ????????
					//question-> temp to be declared first     ???????
					string label1=newLabel();
					string label2=newLabel();
					if($2->getName()=="<"){
						$$->code+="\tjl " + label1+"\n";
					}
					else if(relop=="<="){
						$$->code+="\tjle " + label1+"\n";
					}
					else if(relop==">"){
						$$->code+="\tjg " + label1+"\n";
					}
					else if(relop==">="){
						$$->code+="\tjge " + label1+"\n";
					}
					else if(relop=="=="){
						$$->code+="\tje " + label1+"\n";
					}
					else if(relop=="!="){
						$$->code+="\tjne " + label1+"\n";
					}

					$$->code+="\tmov "+temp +", 0\n";
					$$->code+="\tjmp "+label2 +"\n";
					$$->code+=label1+":\n";
					$$->code+= "\tmov "+temp+", 1\n";
					$$->code+=label2+":\n";
					$$->icgName = temp;
					//delete $3;

					$$->stmt = $1->stmt + " " + $2->getName() + " " + $3->stmt;

				}
				;

				simple_expression : simple_expression ADDOP term
				{

					$$ = new SymbolInfo();
					if($1->getVarType()!="FLOAT" && $3->getVarType()!="FLOAT" ) $$->setVarType("INT");
					else $$->setVarType("FLOAT");
					$$->code = $1->code;
					$$->code += $3->code;
					string temp = newTemp();
					variables.push_back(temp);

					if($2->getName()=="+") {

						$$->code += "\tmov ax, " + $1->icgName + "\n";
						$$->code += "\tadd ax, " + $3->icgName + "\n";
						$$->code += "\tmov " + temp +" , ax\n";
					}
					else{

						$$->code += "\tmov ax, " + $1->icgName + "\n";
						$$->code += "\tsub ax, " + $3->icgName + "\n";
						$$->code += "\tmov " + temp +" , ax\n";
					}
					$$->icgName = temp;
					$$->stmt = $1->stmt + $2->getName() +$3->stmt;

				}
				| term
				{

					$$ = (new SymbolInfo())->copyObject($1); $$->code = $1->code;
				}
				;

				term :	unary_expression
				{

					$$ = (new SymbolInfo())->copyObject($1); $$->code = $1->code;
				}
				|  term MULOP unary_expression
				{
					bool prblm = false;
					$$ = new SymbolInfo();
					string varType1 = $1->getVarType();
					string varType2 = $3->getVarType();
					if(varType1!="FLOAT" && varType2!="FLOAT" ) $$->setVarType("INT");
					else $$->setVarType("FLOAT");

					$$->code=$1->code;
					$$->code += $3->code;
					$$->code += "\tmov ax, "+ $1->icgName+"\n";
					$$->code += "\tmov bx, "+ $3->icgName+"\n";
					string temp=newTemp();
					variables.push_back(temp);
					if($2->getName()=="*"){
						$$->code += "\tmul bx\n";
					}
					else if($2->getName() == "/")
					{

						$$->code += "\tdiv bx\n";

					}
					if($2->getName() == "%")
					{
						if($1->getVarType()=="FLOAT" || $2->getVarType()=="FLOAT")
						{
							logFile <<  "Error at line " << line_count <<" : Unsuported operand for mod operator"<<endl << endl;
							semError++; prblm = true;
						}
						$$->code += "\tmov cx, "+$1->icgName+"\n";
						$$->code += "\tdiv bx\n\tmov dx,ax\n";
						$$->code += "\tmov ax, "+$3->icgName+"\n";
						$$->code += "\tmul dx\n\tsub cx,ax\n\tmov ax,cx\n";
					}
					$$->code += "\tmov "+ temp + ", ax\n";
					$$->icgName = temp;
					$$->errorFound = prblm;
					$$->stmt = $1->stmt + $2->getName() +$3->stmt;

				}
				;

				unary_expression : ADDOP unary_expression
				{
					$$ = (new SymbolInfo())->copyObject($2);
					$$->code = $2->code;
					string temp = newTemp();
					if($1->getName() == "-"){
						$$->code += "\tmov ax, " + $2->icgName + "\n";
						$$->code += "\tneg ax\n";
						$$->code += "\tmov " + temp+ " , ax\n";
					}
					$$->icgName = temp;

				}
				| NOT unary_expression
				{

					$$ = (new SymbolInfo())->copyObject($2);
					$$->code=$2->code;
					string temp=newTemp();
					variables.push_back(temp);
					$$->code="\tmov ax, " + $2->icgName + "\n";
					$$->code+="\tnot ax\n";
					$$->code+="\tmov "+temp+", ax";
					$$->icgName = temp;
				}
				| factor
				{

					$$ = (new SymbolInfo())->copyObject($1); $$->code = $1->code;

				}
				;

				factor	: variable
				{

					$$ = (new SymbolInfo())->copyObject($1); $$->code = $1->code;

				}
				| ID LPAREN argument_list RPAREN
				{

					SymbolInfo *temp=new SymbolInfo();

					temp = table.lookUpInScopes((new SymbolInfo())->setName($1->getName())->setIDType( "FUNC") );
					if(temp == NULL){
						logFile <<  "Error at line " << line_count <<" : Function " <<$1->getName() <<" doesn't exist"<<endl << endl;
						$$ = new SymbolInfo(); $$->errorFound = true;
					}
					else{
						int sz = temp->ParamList.size();
						if(sz > $3->ParamList.size())
						{
							logFile <<  "Error at line " << line_count <<"  : Function " <<$1->getName() <<" too few arguments"<<endl << endl;
							semError++; $$ = new SymbolInfo(); $$->errorFound = true;
						}
						else if(sz < $3->ParamList.size())
						{
							logFile <<  "Error at line " << line_count <<"  : Function " <<$1->getName() <<" too many arguments"<<endl << endl;
							semError++; $$ = new SymbolInfo(); $$->errorFound = true;
						}
						else {
							bool er = false;
							for(int i=0;i<sz;i++)
							{

								if($3->ParamList[i]!=temp->ParamList[i])
								{
									logFile <<  "Error at line " << line_count <<"  : Type Mismatch"<<endl << endl;
									semError++; er = true; break;
								}
							}
							SymbolInfo *tmp2 = (new SymbolInfo())->setIDType("FUNC")->setName($1->getName())->setVarType(temp->getFuncRetType())->setFuncRetType(temp->getFuncRetType());
							$$ = tmp2;
							$$->errorFound = er;
							$$->code = $3->code;
							$$->code += setParameter($3->ParamVal);
							$$->code += "\tcall "+$1->getName()+"\n";
							$$->icgName = FuncRetVar;

						}

					}
					$$->stmt = $1->getName() + "(" + $3->stmt +")";

				}
				| LPAREN expression RPAREN
				{

					$$ = (new SymbolInfo())->copyObject($2); $$->code = $2->code;
					$$->stmt = "(" + $2->stmt +")";

				}
				| CONST_INT{

					$1->setVarType("INT")->setIDType("VAR");
					$1->setValue(atoi($1->getName().c_str()));
					$1->stmt = $1->getName();
					$$ = $1;
				}
				| CONST_FLOAT
				{

					$1->setVarType("FLOAT")->setIDType("VAR");
					$1->setValue(atof($1->getName().c_str()));
					$1->stmt = $1->getName();
					$$ = $1;
				}
				| variable INCOP
				{
					string newTmp = newTemp();
					variables.push_back(newTmp);
					$$ = (new SymbolInfo())->copyObject($1); $$->code = $1->code;
					$$->code += "\tmov ax , " + $$->icgName+ "\n";
					$$->code += "\tmov " + newTmp+ " , ax\n";
					$$->code += "\tadd ax, 1\n";
					$$->code += "\tmov " + $$->icgName+ " , ax\n";
					$$->icgName = newTmp;
				}
				| variable DECOP
				{

					string newTmp = newTemp();
					variables.push_back(newTmp);
					$$ = (new SymbolInfo())->copyObject($1); $$->code = $1->code;
					$$->code += "\tmov ax , " + $$->icgName+ "\n";
					$$->code += "\tmov " + newTmp+ " , ax\n";
					$$->code += "\tsub ax, 1\n";
					$$->code += "\tmov " + $$->icgName+ " , ax\n";
					$$->icgName = newTmp;
				}
				;

				variable : ID
				{

					SymbolInfo *tmp = table.lookUpInScopes((new SymbolInfo())->setName($1->getName())->setIDType("VAR"));
					SymbolInfo *cur = table.lookUpInCurScope((new SymbolInfo())->setName($1->getName())->setIDType("ARA"));


					$$ = new SymbolInfo();
					if(cur!=NULL)
					{
						logFile <<  "Error at line " << line_count << " : Trying to access array like normal variable! "   <<  endl << endl;
						semError++;
					}
					else if(tmp==NULL)
					{
						logFile <<  "Error at line " << line_count << " :  Undeclared Variable: "  << $1->getName()  <<  endl << endl;
						semError++;
						table.printAll(logFile);
					}
					else $$ = tmp;



				}
				| ID LTHIRD expression RTHIRD /* ara variable */
				{

					bool prblm = false;

					$$ = new SymbolInfo();
					SymbolInfo *tmp = table.lookUpInScopes((new SymbolInfo())->setName($1->getName())->setIDType("ARA"));
					SymbolInfo *cur = table.lookUpInCurScope((new SymbolInfo())->setName($1->getName())->setIDType("VAR"));

					if(cur!=NULL)
					{
						logFile <<  "Error at line " << line_count << " : "<<$1->getName()<<" not an Array "   <<  endl << endl;
						semError++; prblm = true;
					}
					else if(tmp==NULL)
					{

						logFile <<  "Error at line " << line_count << " :  Undeclared Variable: "  << $1->getName()  <<  endl << endl;
						semError++; prblm = true;
					}
					else{
						if($3->getVarType()=="FLOAT")
						{
							logFile <<  "Error at line " << line_count << " : " << " Non-integer Array Index " <<  endl << endl;
							semError++;
							prblm = true;
						}

						if($3->getIDType()=="FUNC" && $3->getFuncRetType()!="INT")
						{
							logFile <<  "Error at line " << line_count << " : " <<$1->getName() << " Non-integer Array Index" <<  endl << endl;
							semError++;
							prblm = true;

							//TBMF

						}
						SymbolInfo *tmp2 = (new SymbolInfo())->setName($1->getName())->setIDType("ARA")->setIndex($3->code+"\n"+"\tmov bx, " +$3->icgName +"\n")->setVarType(tmp->getVarType());

						$$ = tmp2;


						$$->stmt = $1->getName() + "["+$3->stmt + "]";
						$$->errorFound = prblm;


						$$->code=$3->code ;
						$$->code += "\tmov bx, " +$3->icgName +"\n";
						$$->code += "\tmov ax, " +tmp->icgName+"[bx]\n";
						string newTmp = newTemp();
						variables.push_back(newTmp);
						$$->code += "\tmov "+newTmp+",ax\n";
						$$->icgName = newTmp;
						$$->writeData = tmp->icgName;

					}
				}
				;

				argument_list	: arguments{
					$$ = (new SymbolInfo())->copyObject($1); $$->code = $1->code;
				}
				|
				;

				arguments	:arguments COMMA logic_expression {

					$1->ParamList.push_back($3->getVarType());
					$1->ParamVal.push_back($3->icgName);
					$$ = $1 ;
					$$->code+= $3->code;

				}
				|logic_expression {
					SymbolInfo *tmp = new SymbolInfo();
					tmp->ParamList.push_back($1->getVarType());
					tmp->ParamVal.push_back($1->icgName);
					$$ =tmp;

					$$->code = $1->code;
				}
				;


				%%


				int main(int argc,char *argv[])
				{

					if((fp=fopen(argv[1],"r"))==NULL)
					{
						printf("Cannot Open Input File.\n");
						exit(1);
					}

					logFile.open("log.txt");
					optimizedFile.open("Code.asm");
					asmFile.open("code.asm");
					table.setStream(logFile);

					yyin = fp;
					yyparse();




					logFile << "Total Errors: "<<semError<<endl<<endl;
					logFile.close();
					asmFile.close();
					optimizedFile.close();
					exit(0);
					return 0;
				}
