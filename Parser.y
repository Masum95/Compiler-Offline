%{
	#include<iostream>
	#include<cstdlib>
	#include<cstring>
	#include<cmath>
	#include "SymbolTable.h"
	//#define YYSTYPE SymbolInfo*

	using namespace std;

	int yyparse(void);
	int yylex(void);
	extern FILE *yyin;
	extern int line_count;
	FILE *fp;
	ofstream logFile, errorFile;

	int syntaxError = 0;
	int semError = 0;
	string variable_type;
	vector<SymbolInfo*> params;
	vector<string> args;
	int argsWithId = 0;
	SymbolTable table(11);


	void yyerror(const char *s)
	{
		printf("%s\n",s);
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


	%type <symVal> type_specifier expression logic_expression rel_expression simple_expression term unary_expression factor variable argument_list arguments var_declaration func_declaration func_definition parameter_list compound_statement declaration_list statements statement expression_statement program unit

	%nonassoc second_precedence
	%nonassoc ELSE
	%error-verbose

	%%

	start : program
	{
		logFile << "At line no: "<< line_count << " : start : program\n"<< endl;
	}
	;

	program : program unit
	{
		logFile << "At line no: "<< line_count << " : program : program unit\n"<< endl;
		$1->stmt = $1->stmt + "\n\n" + $2->stmt;
		$$ = $1;
		logFile<<$$->stmt<<endl<<endl;
	}
	| unit
	{
		logFile << "At line no: "<< line_count << " : program : unit\n"<< endl;
		$$ = $1;
		logFile<<$$->stmt<<endl<<endl;
	}
	;

	unit : 	var_declaration
	{
		logFile << "At line no: "<< line_count << " : unit : var_declaration\n"<< endl;
		$$ = $1;
		logFile<<$$->stmt<<endl<<endl;
	}
	|
	func_declaration
	{
		logFile << "At line no: "<< line_count << " : unit : func_declaration\n"<< endl;
		$$ = $1;
		logFile<<$$->stmt<<endl<<endl;
	}
	|
	func_definition
	{
		logFile << "At line no: "<< line_count << " : unit : func_definition\n"<< endl;
		$$ = $1;
		logFile<<$$->stmt<<endl<<endl;
	}
	;

	func_declaration : type_specifier ID LPAREN parameter_list RPAREN SEMICOLON
	{
		string exp = $1->stmt + " " + $2->getName() + "(" + $4->stmt + ");";

		SymbolInfo *asgn = (new SymbolInfo());
		asgn->stmt = exp;
		$$ = asgn;

		logFile << "At line no: "<< line_count << " : func_declaration : 	type_specifier ID LPAREN parameter_list RPAREN SEMICOLON\n"<<endl;
		logFile << $$->stmt << endl << endl;
		SymbolInfo* isDeclared = table.lookUpInScopes((new SymbolInfo())->setName($2->getName())->setIDType( "FUNC") );
		if(isDeclared!=NULL && isDeclared->funcDeclared==true)
		{
			errorFile << "Error at line " << line_count << " Function "<< $2->getName() <<" already declared" << endl << endl;
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
			args.clear();params.clear();
		}

	}
	|type_specifier ID LPAREN parameter_list RPAREN error
	{
		errorFile << "Error at line " << line_count << " ; missing" << endl << endl;
		semError++;
	}
	;

	func_definition : type_specifier ID LPAREN parameter_list RPAREN
	{
		SymbolInfo *tmp = table.lookUpInScopes((new SymbolInfo())->setName($2->getName())->setIDType("FUNC"));


		if(argsWithId!=args.size())
		{
			errorFile << "Error at line " << line_count << " Parameter mismatch for Function "<< $2->getName() << endl << endl;
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
				}
				table.insert(tmp2);
			}
			else{

				if(tmp->isFuncDefined()){
					errorFile << "Error at line " << line_count << "Function "<< $2->getName() <<" already defined" << endl << endl;
					semError++;

				}

				else if(tmp->getFuncRetType() != $1->getVarType()){
					errorFile << "Error at line " << line_count << ": Function "<< $2->getName() <<" :return type doesn't match declaration" << endl << endl;
					semError++;

				}
				else if (tmp->ParamList.size()!=argsWithId )
				{
					errorFile << "Error at line " << line_count << "Function "<< $2->getName() <<" :Parameter list does not match declaration" << endl << endl;
					semError++;
				}
				else{
					for(int i = 0; i<tmp->ParamList.size(); i++){
						if(tmp->ParamList[i] != args[i]){
							errorFile << "Error at line " << line_count << "Function "<< $2->getName()<< " :argument mismatch" << endl << endl;
							semError++;
						}
					}
				}

			}
		}
		args.clear();
		argsWithId = 0;
		} compound_statement{

			logFile << "Line " << line_count << " : func_definition : type_specifier ID LPAREN parameter_list RPAREN compound_statement\n"<<endl;
			string exp = $1->stmt + " " + $2->getName() + "(" + $4->stmt + ")\n" + $7->stmt;
			SymbolInfo *asgn = (new SymbolInfo());
			asgn->stmt = exp;
			$$ = asgn;
			logFile << $$->stmt << endl << endl;
		}
		;


		parameter_list  : parameter_list COMMA type_specifier ID
		{
			logFile << "At line no: "<< line_count << " : parameter_list  : parameter_list COMMA type_specifier ID\n"<<endl;

			string exp = $1->stmt+ "," + $3->stmt + " " + $4->getName();
			SymbolInfo *asgn = new SymbolInfo();
			asgn->stmt = exp;
			$$ = asgn;
			logFile << $$->stmt << endl << endl;

			argsWithId++;
			args.push_back(variable_type);
			SymbolInfo *tmp = new SymbolInfo();
			tmp->setIDType("VAR")->setType("ID")->setVarType(variable_type)->setName($4->getName());
			params.push_back(tmp);
		}
		| parameter_list COMMA type_specifier
		{

			logFile << "At line no: "<< line_count << " : parameter_list  : parameter_list COMMA type_specifier\n"<< endl;
			args.push_back(variable_type);

			string exp = $1->stmt+ "," + $3->stmt;
			SymbolInfo *asgn = new SymbolInfo();
			asgn->stmt = exp;
			$$ = asgn;
			logFile << $$->stmt << endl << endl;
		}
		| type_specifier ID
		{
			logFile << "At line no: "<< line_count << " : parameter_list  : type_specifier ID\n"<<endl;
			argsWithId++;
			args.push_back(variable_type);
			SymbolInfo *tmp = new SymbolInfo();
			tmp->setIDType("VAR")->setType("ID")->setVarType(variable_type)->setName($2->getName());
			params.push_back(tmp);

			string exp = $1->stmt + " " + $2->getName();
			SymbolInfo *asgn = new SymbolInfo();
			asgn->stmt = exp;
			$$ = asgn;
			logFile << $$->stmt << endl << endl;
		}
		| type_specifier
		{
			logFile << "At line no: "<< line_count << " : parameter_list  : type_specifier\n"<< endl;
			args.push_back(variable_type);

			SymbolInfo *asgn = new SymbolInfo();
			asgn->stmt = $1->stmt;
			$$ = asgn;
			logFile << $$->stmt << endl << endl;

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
					logFile << "At line no: "<< line_count << " : compound_statement : LCURL statements RCURL\n"<< endl;

					SymbolInfo *asgn = new SymbolInfo();
					asgn->stmt = "{\n" + $3->stmt + "\n}";
					$$ = asgn;
					logFile << $$->stmt << endl << endl;
					table.printAll(logFile);
					table.exitScope();
				}
				| LCURL RCURL { logFile << "At line no: "<< line_count << " : compound_statement : LCURL RCURL\n"<< endl; }
				;


				var_declaration : type_specifier declaration_list SEMICOLON {
					string exp = $1->stmt +  " "+ $2->stmt+";";
					logFile << "At line no: "<< line_count << " : var_declaration : type_specifier declaration_list SEMICOLON\n"<< endl;
					logFile<<exp<<endl<<endl;
					SymbolInfo *tmp = new SymbolInfo();
					tmp->stmt = exp;
					$$ = tmp;

				}
				|type_specifier declaration_list error
				{
					errorFile << "Error at line " << line_count << "Inappropriate declaration" << endl << endl;
					semError++;
				}
				;

				type_specifier	: INT
				{
					logFile << "At line no: "<< line_count << " : type_specifier	: INT\n"<< endl;
					logFile<<"int"<<endl<<endl;

					SymbolInfo* tmp= new SymbolInfo();
					tmp->setVarType("INT");
					tmp->stmt = "int";
					variable_type = "INT";
					$$ = tmp;
				}
				| FLOAT
				{
					logFile << "At line no: "<< line_count << " : type_specifier	: FLOAT\n"<< endl;
					logFile<<"float"<<endl<<endl;

					SymbolInfo* tmp= new SymbolInfo();
					tmp->setVarType("FLOAT");
					tmp->stmt = "float";
					variable_type = "FLOAT";
					$$ = tmp;
				}
				| VOID
				{
					logFile << "At line no: "<< line_count << " : type_specifier	: VOID\n"<< endl;
					logFile<<"void"<<endl<<endl;
					SymbolInfo* tmp= new SymbolInfo();
					tmp->setVarType("VOID");
					tmp->stmt = "void";
					variable_type = "VOID";
					$$ = tmp;
				}
				;

				declaration_list : declaration_list COMMA ID
				{

					string exp = $1->stmt +  ","+ $3->getName();
					logFile << "At line no: "<< line_count << " : declaration_list : 	declaration_list COMMA ID\n"<<endl;
					$1->stmt = exp;
					$$ = $1;
					logFile << exp << endl<<endl;
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
							table.insert(tmp2);
						}
						else{
							errorFile << "Error at line " << line_count << ": Variable "<< $3->getName() <<" already declared" << endl << endl;
							semError++;
						}
					}
				}
				| declaration_list COMMA ID LTHIRD CONST_INT RTHIRD
				{
					$1->stmt = $1->stmt +  ","+ $3->getName() +"[" + $5->getName() + "]";
					logFile << "At line no: "<< line_count << " : declaration_list : 	declaration_list COMMA ID LTHIRD CONST_INT RTHIRD\n"<<endl;
					$$ = $1 ;
					logFile << $$->stmt << endl << endl;

					if(variable_type == "VOID"){
						errorFile << "Error at line " << line_count << " : array type can't be void" << endl << endl;
						semError++;
					}
					else{
						SymbolInfo *tmp = table.lookUpInCurScope((new SymbolInfo())->setName($3->getName())->setIDType("ARA"))->setType("ID");
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
							if(variable_type=="INT")
							{
								for(int i=0;i<sz;i++)
								{
									tmp2->ints.push_back(0);
								}

							}
							if(variable_type=="FLOAT")
							{
								for(int i=0;i<sz;i++)
								{
									tmp2->floats.push_back(0);
								}
							}
							if(variable_type=="CHAR")
							{
								for(int i=0;i<sz;i++)
								{
									tmp2->chars.push_back('\0');
								}
							}
							tmp2->stmt = $1->stmt + "," +$3->getName() + "[" + $5->getName() + "]";

							table.insert(tmp2);

						}
					}
				}
				| ID
				{
					logFile << "At line no: "<< line_count << " : declaration_list :	ID\n"<<endl;

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
							table.insert(tmp2);

						}
						else{
							errorFile << "Error at line " << line_count << ": Multiple Declaration of "<<$1->getName() << endl << endl;
							semError++;
						}

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
							if(variable_type=="INT")
							{
								for(int i=0;i<sz;i++)
								{
									tmp2->ints.push_back(0);
								}

							}
							if(variable_type=="FLOAT")
							{
								for(int i=0;i<sz;i++)
								{
									tmp2->floats.push_back(0);
								}
							}
							if(variable_type=="CHAR")
							{
								for(int i=0;i<sz;i++)
								{
									tmp2->chars.push_back('\0');
								}
							}
							table.insert(tmp2);

						}
					}
				}
				;

				statements : statement{logFile << "At line no: "<< line_count << " : statements : statement\n"<< endl; $$ = $1 ;logFile<<$1->stmt<<endl<<endl;}
				| statements statement{logFile << "At line no: "<< line_count << " : statements : statements statement\n"<< endl;
				$2->stmt = $1->stmt + "\n" + $2->stmt;
				$$ = $2;
				logFile<<$$->stmt<<endl<<endl;
			}
			;


			statement : var_declaration{logFile << "At line no: "<< line_count << " : statement : var_declaration\n"<< endl; $$ = $1 ;logFile<<$1->stmt<<endl<<endl;}
			| expression_statement{logFile << "At line no: "<< line_count << " : statement : expression_statement\n"<< endl; $$ = $1 ;logFile<<$1->stmt<<endl<<endl;}
			| compound_statement{logFile << "At line no: "<< line_count << " : statement : compound_statement\n"<< endl; $$ = $1 ;logFile<<$1->stmt<<endl<<endl;}
			| FOR LPAREN expression_statement expression_statement expression RPAREN statement
			{
				logFile << "At line no: "<< line_count << " : statement : FOR LPAREN expression_statement expression_statement expression RPAREN statement\n"<< endl;


				SymbolInfo *asgn = new SymbolInfo();
				asgn->stmt = "for(" + $3->stmt + $4->stmt + $5->stmt + ")\n" + $7->stmt;
				$$ = asgn;
				logFile << $$->stmt << endl << endl;
			}
			| IF LPAREN expression RPAREN statement  %prec second_precedence
			{
				logFile << "At line no: "<< line_count << " : statement : IF LPAREN expression RPAREN statement\n"<< endl;


				SymbolInfo *asgn = new SymbolInfo();
				asgn->stmt ="if(" + $3->stmt +")\n" + $5->stmt ;
				$$ = asgn;
				logFile << $$->stmt << endl << endl;
			}
			| IF LPAREN expression RPAREN statement ELSE statement
			{
				logFile << "At line no: "<< line_count << " : statement : IF LPAREN expression RPAREN statement ELSE statement\n"<< endl;

				SymbolInfo *asgn = new SymbolInfo();
				asgn->stmt ="if(" + $3->stmt +")\n" + $5->stmt +"\nelse" + $7->stmt;
				$$ = asgn;
				logFile << $$->stmt << endl << endl;
			}
			| WHILE LPAREN expression RPAREN statement{
				logFile << "At line no: "<< line_count << " : statement : WHILE LPAREN expression RPAREN statement\n"<< endl;

				SymbolInfo *asgn = new SymbolInfo();
				asgn->stmt ="while(" +$3->stmt +")\n" + $5->stmt ;
				$$ = asgn;
				logFile << $$->stmt << endl << endl;
			}
			| PRINTLN LPAREN ID RPAREN SEMICOLON{
				logFile << "At line no: "<< line_count << " : statement : PRINTLN LPAREN ID RPAREN SEMICOLON\n"<< endl;

				//TBMF
			}
			| PRINTLN LPAREN ID RPAREN error
			{
				errorFile << "Error at line " << line_count << "; missing" << endl << endl;
				semError++;
			}
			| RETURN expression SEMICOLON{
				logFile << "At line no: "<< line_count << " : statement : RETURN expression SEMICOLON\n"<< endl;

				SymbolInfo *asgn = new SymbolInfo();
				asgn->stmt ="return " + $2->stmt +";" ;
				$$ = asgn;
				logFile << $$->stmt << endl << endl;
			}
			|RETURN expression error
			{
				errorFile << "Error at line " << line_count << "; missing" << endl << endl;
				semError++;
			}
			;

			expression_statement 	: SEMICOLON{
				logFile << "At line no: "<< line_count << " : expression_statement : SEMICOLON\n"<< endl;

				SymbolInfo *asgn = new SymbolInfo();
				asgn->stmt =";" ;
				$$ = asgn;
				logFile << $$->stmt << endl << endl;
			}
			| expression SEMICOLON {
				logFile << "At line no: "<< line_count << " : expression_statement : expression SEMICOLON\n"<< endl;

				SymbolInfo *asgn = new SymbolInfo();
				asgn->stmt = $1->stmt + ";" ;
				$$ = asgn;
				logFile << $$->stmt << endl << endl;
			}
			|expression error
			{
				errorFile << "Error at line " << line_count << "; missing" << endl << endl;
				semError++;
			}
			;



			expression : logic_expression
			{
				logFile << "At line no: "<< line_count << " : expression : logic_expression\n"<< endl;
				$$ = $1;
				logFile << $$->stmt << endl << endl;
				//TBMF
			}
			| variable ASSIGNOP logic_expression
			{
				logFile << "At line no: "<< line_count << " : expression : variable ASSIGNOP logic_expression\n"<< endl;
				string vType = $1->getVarType();
				SymbolInfo *tmp;
				if($1->getIDType()=="VAR") tmp = table.lookUpInScopes((new SymbolInfo())->setName($1->getName())->setIDType("VAR"));
				else if($1->getIDType()=="ARA") tmp = table.lookUpInScopes((new SymbolInfo())->setName($1->getName())->setIDType("ARA"));
				if(tmp==NULL)
				{

				}
				else if($1->errorFound || $3->errorFound);
				else{
					if(tmp->getVarType()!=$3->getVarType())
					{
						errorFile << "Warning at line " << line_count << ": Type Mismatch" << endl << endl;
					}
					if($1->getIDType()=="VAR")
					{
						if($3->getIDType()=="VAR") $1->setValue($3->getValue());
						if($3->getIDType()=="ARA")$1->setValue($3->getAraElementValue($3->getIndex()));
					}
					else{ // if araType
						if($3->getIDType()=="VAR")$1->setAraElementValue($1->getIndex(), $3->getValue());
						if($3->getIDType()=="ARA")$1->setAraElementValue($1->getIndex(), $3->getAraElementValue($3->getIndex()));
					}

				}
				$$ = $1;
				$$->stmt = $1->stmt + "=" + $3->stmt;
				logFile << $$->stmt << endl << endl;
				//-----------Table to be printed ----
			}
			;

			logic_expression : rel_expression
			{
				logFile << "At line no: "<< line_count << " : logic_expression : rel_expression\n"<< endl;
				$$ = $1;
				logFile << $$->stmt << endl << endl;
				//TBMF
			}
			| rel_expression LOGICOP rel_expression
			{
				logFile << "At line no: "<< line_count << " : logic_expression : rel_expression LOGICOP rel_expression\n"<< endl;
				SymbolInfo *tmp = (new SymbolInfo())->setVarType("INT");
				int val1,val2,ans;
				val1 = $1->getValue();
				val2 = $3->getValue();

				if($2->getName()=="&&")
				{
					if(val1==1 && val2==1 ) ans = 1;
					else ans = 0;
				}
				if($2->getName()=="||")
				{
					if(val1==0 && val2==0 ) ans = 0;
					else ans = 1;
				}
				tmp->intVal = ans;
				$$ = tmp;

				$$->stmt = $1->stmt + " " + $2->getName() + " " + $3->stmt;
				logFile << $$->stmt << endl << endl;
			}
			;

			rel_expression	: simple_expression
			{
				logFile << "At line no: "<< line_count << " : rel_expression : simple_expression\n"<< endl;
				$$ = $1;
				logFile << $$->stmt << endl << endl;
			}
			| simple_expression RELOP simple_expression
			{
				string relop = $2->getName();
				int ans;
				logFile << "At line no: "<< line_count << " : rel_expression : simple_expression RELOP simple_expression\n"<< endl;
				SymbolInfo* temp = (new SymbolInfo())->setVarType("INT");
				double val1,val2;

				if($1->getIDType()=="VAR") val1= $1->getValue();
				if($1->getIDType()=="ARA") val1= $1->getAraElementValue($1->getIndex());

				if($3->getIDType()=="VAR") val2= $3->getValue();
				if($3->getIDType()=="ARA") val2= $3->getAraElementValue($3->getIndex());

				if(relop=="==") ans = ( val1 == val2 )? 1 : 0 ;
				if(relop==">=") ans = ( val1 >= val2 )? 1 : 0 ;
				if(relop=="<=") ans = ( val1 <= val2 )? 1 : 0 ;
				if(relop==">") ans = ( val1 > val2)? 1 : 0 ;
				if(relop=="<") ans = ( val1 < val2 )? 1 : 0 ;

				temp->intVal = ans;
				temp->setVarType("INT");
				$$ = temp;

				$$->stmt = $1->stmt + " " + $2->getName() + " " + $3->stmt;
				logFile << $$->stmt << endl << endl;
			}
			;

			simple_expression : simple_expression ADDOP term
			{
				logFile << "At line no: "<< line_count << " : simple_expression : simple_expression ADDOP term\n"<< endl;
				double val1,val2,ans;
				SymbolInfo *tmp = new SymbolInfo();
				if($1->getVarType()!="FLOAT" && $1->getVarType()!="FLOAT" ) tmp->setVarType("INT");
				else tmp->setVarType("FLOAT");

				if($1->getIDType()=="VAR") val1= $1->getValue();
				if($1->getIDType()=="ARA") val1= $1->getAraElementValue($1->getIndex());

				if($3->getIDType()=="VAR") val2= $3->getValue();
				if($3->getIDType()=="ARA") val2= $3->getAraElementValue($3->getIndex());

				if($2->getName() == "+") ans = val1 + val2;
				else ans = val1 - val2;

				tmp->setValue(ans);
				$$ = tmp;
				$$->stmt = $1->stmt + $2->getName() +$3->stmt;
				logFile << $$->stmt << endl << endl;
			}
			| term
			{
				logFile << "At line no: "<< line_count << " : simple_expression : term\n"<< endl;
				$$ = $1;
				logFile << $$->stmt << endl << endl;
			}
			;

			term :	unary_expression
			{
				logFile << "At line no: "<< line_count << " : term : unary_expression\n"<< endl;
				$$ = $1;
				logFile << $$->stmt << endl << endl;
			}
			|  term MULOP unary_expression
			{
				bool prblm = false;
				logFile << "At line no: "<< line_count << " : term : term MULOP unary_expression\n"<< endl;
				double val1,val2,ans;
				SymbolInfo *tmp = new SymbolInfo();
				string varType1 = $1->getVarType();
				string varType2 = $3->getVarType();
				if(varType1!="FLOAT" && varType2!="FLOAT" ) tmp->setVarType("INT");
				else tmp->setVarType("FLOAT");

				if($1->getIDType()=="VAR") val1= $1->getValue();
				if($1->getIDType()=="ARA") val1= $1->getAraElementValue($1->getIndex());

				if($3->getIDType()=="VAR") val2= $3->getValue();
				if($3->getIDType()=="ARA") val2= $3->getAraElementValue($3->getIndex());

				if($2->getName() == "*") ans = val1 * val2;
				else if($2->getName() == "/")
				{
					if(val2==0)
					{
						errorFile << "Error at line " << line_count <<" : Divide by zero"<<endl << endl;
						semError++; prblm = true;
					}
					else if(varType1 !="INT" && varType2!="INT") ans =  ( (int) val1 ) / ( (int) val2 );
					else ans = val1 / val2;
				}
				if($2->getName() == "%")
				{
					if(varType1=="FLOAT" || varType2=="FLOAT")
					{
						errorFile << "Error at line " << line_count <<" : Unsuported operand for mod operator"<<endl << endl;
						semError++; prblm = true;
					}
					else if(val2==0)
					{
						errorFile << "Error at line " << line_count <<" : MOD by zero"<<endl << endl;
						semError++; prblm = true;
					}
					else ans = (int)val1 % (int)val2;
				}
				tmp->setValue(ans);
				$$ = tmp;
				$$->errorFound = prblm;
				$$->stmt = $1->stmt + $2->getName() +$3->stmt;
				logFile << $$->stmt << endl << endl;
			}
			;

			unary_expression : ADDOP unary_expression
			{
				logFile << "At line no: "<< line_count << " : unary_expression : ADDOP unary_expression\n"<< endl;
				if($1->getName() == "-"){
					if($2->getVarType() == "VAR"){
						$2->setValue(-1*($2->getValue()));
					}
					else if($2->getVarType() == "ARA"){
						$2->setAraElementValue($2->getIndex(),-1*($2->getAraElementValue($2->getIndex())));
					}
				}
				$$ = $2;
				$$->stmt = $1->getName() + $2->stmt;
				logFile << $$->stmt << endl << endl;
			}
			| NOT unary_expression
			{
				logFile << "At line no: "<< line_count << " : unary_expression : NOT unary_expressionn"<< endl;
				double val;
				if($2->getVarType() == "VAR"){
					val = $2->getValue();
				}
				else if($2->getVarType() == "ARA"){
					val = $2->getAraElementValue($2->getIndex());
				}
				if(val==0) val = 1;
				else val = 1;
				SymbolInfo* temp = (new SymbolInfo())->setVarType("INT");
				temp->setIDType("VAR")->setValue(val);
				$$ = temp;

				$$->stmt ="!" + $2->stmt;
				logFile << $$->stmt << endl << endl;
			}
			| factor
			{
				logFile << "At line no: "<< line_count << " : unary_expression : factor\n"<< endl;
				$$ = $1;
				logFile << $$->stmt << endl << endl;
			}
			;

			factor	: variable
			{
				logFile << "At line no: "<< line_count << " : factor : variable\n"<< endl;
				$$ = $1;
				logFile << $$->stmt << endl << endl;
			}
			| ID LPAREN argument_list RPAREN
			{
				logFile << "At line no: "<< line_count << " : factor : ID LPAREN argument_list RPAREN\n"<<endl;
				SymbolInfo *temp=new SymbolInfo();

				temp = table.lookUpInScopes((new SymbolInfo())->setName($1->getName())->setIDType( "FUNC") );
				if(temp == NULL){
					errorFile << "Error at line " << line_count <<" : Function " <<$1->getName() <<" doesn't exist"<<endl << endl;
					$$ = new SymbolInfo(); $$->errorFound = true;
				}
				else{
					int sz = temp->ParamList.size();
					if(sz > $3->ParamList.size())
					{
						errorFile << "Error at line " << line_count <<"  : Function " <<$1->getName() <<" too few arguments"<<endl << endl;
						semError++; $$ = new SymbolInfo(); $$->errorFound = true;
					}
					else if(sz < $3->ParamList.size())
					{
						errorFile << "Error at line " << line_count <<"  : Function " <<$1->getName() <<" too many arguments"<<endl << endl;
						semError++; $$ = new SymbolInfo(); $$->errorFound = true;
					}
					else {
						bool er = false;
						for(int i=0;i<sz;i++)
						{
							if($3->ParamList[i]!=temp->ParamList[i])
							{
								errorFile << "Error at line " << line_count <<"  : Type Mismatch"<<endl << endl;
								semError++; er = true; break;
							}
						}
						SymbolInfo *tmp2 = (new SymbolInfo())->setIDType("FUNC")->setName($1->getName())->setVarType(temp->getFuncRetType())->setFuncRetType(temp->getFuncRetType());
						$$ = tmp2;
						$$->errorFound = er;


					}

				}
				$$->stmt = $1->getName() + "(" + $3->stmt +")";
				logFile << $$->stmt << endl << endl;
			}
			| LPAREN expression RPAREN
			{
				logFile << "At line no: "<< line_count << " : factor : LPAREN expression RPAREN\n"<< endl;
				$$ = $2;
				$$->stmt = "(" + $2->stmt +")";
				logFile << $$->stmt << endl << endl;
			}
			| CONST_INT{
				logFile << "At line no: "<< line_count << " : factor : CONST_INT\n"<<endl;
				logFile << $1->getName()<< endl << endl;
				$1->setVarType("INT")->setIDType("VAR");
				$1->setValue(atoi($1->getName().c_str()));
				$1->stmt = $1->getName();
				$$ = $1;
			}
			| CONST_FLOAT
			{
				logFile << "At line no: "<< line_count << " : factor : CONST_FLOAT\n"<<endl;
				logFile << $1->getName() << endl << endl;
				$1->setVarType("FLOAT")->setIDType("VAR");
				$1->setValue(atof($1->getName().c_str()));
				$1->stmt = $1->getName();
				$$ = $1;
			}
			| variable INCOP
			{
				logFile << "At line no: "<< line_count << " : factor : variable INCOP\n"<< endl;

				if($1->getIDType() == "VAR"){
					$1->setValue($1->getValue()+1);
				}
				else if($1->getIDType() == "ARA"){
					$1->setAraElementValue($1->getIndex(),$1->getAraElementValue($1->getIndex())+1);
				}
				SymbolInfo *tmp = new SymbolInfo();
				tmp->stmt = $1->stmt + "++";
				$$ = tmp;
				logFile << $$->stmt << endl << endl;
			}
			| variable DECOP
			{
				logFile << "At line no: "<< line_count << " : factor : variable DECOP\n"<< endl;


				if($1->getIDType() == "VAR"){
					$1->setValue($1->getValue()-1);
				}
				else if($1->getIDType() == "ARA"){
					$1->setAraElementValue($1->getIndex(),$1->getAraElementValue($1->getIndex())-1);
				}
				SymbolInfo *tmp = new SymbolInfo();
				tmp->stmt = $1->stmt + "--";
				$$ = tmp;
				logFile << $$->stmt << endl << endl;
			}
			;

			variable : ID
			{
				logFile << "At line no: "<< line_count << " : variable : ID\n"<<endl;
				logFile << $1->getName() << endl << endl;
				SymbolInfo *tmp = table.lookUpInScopes((new SymbolInfo())->setName($1->getName())->setIDType("VAR"));
				SymbolInfo *cur = table.lookUpInCurScope((new SymbolInfo())->setName($1->getName())->setIDType("ARA"));
				$$ = new SymbolInfo();
				if(cur!=NULL)
				{
					errorFile << "Error at line " << line_count << " : Trying to access array like normal variable! "   <<  endl << endl;
					semError++;
				}
				else if(tmp==NULL)
				{
					errorFile << "Error at line " << line_count << " :  Undeclared Variable: "  << $1->getName()  <<  endl << endl;
					semError++;
				}
				else $$ = tmp;

				$$->stmt =  $1->getName();


			}
			| ID LTHIRD expression RTHIRD /* ara variable */
			{
				bool prblm = false;
				logFile << "At line no: "<< line_count << " : variable : ID LTHIRD expression RTHIRD\n"<<endl;
				$$ = new SymbolInfo();
				SymbolInfo *tmp = table.lookUpInScopes((new SymbolInfo())->setName($1->getName())->setIDType("ARA"));
				SymbolInfo *cur = table.lookUpInCurScope((new SymbolInfo())->setName($1->getName())->setIDType("VAR"));

				if(cur!=NULL)
				{
					errorFile << "Error at line " << line_count << " : "<<$1->getName()<<" not an Array "   <<  endl << endl;
					semError++; prblm = true;
				}
				else if(tmp==NULL)
				{
					errorFile << "Error at line " << line_count << " :  Undeclared Variable: "  << $1->getName()  <<  endl << endl;
					semError++; prblm = true;
				}
				else{
					if($3->getVarType()=="FLOAT")
					{
						errorFile << "Error at line " << line_count << " : " << " Non-integer Array Index " <<  endl << endl;
						semError++;
						prblm = true;
					}

					if($3->getIDType()=="FUNC" && $3->getFuncRetType()!="INT")
					{
						errorFile << "Error at line " << line_count << " : " <<$1->getName() << " Non-integer Array Index" <<  endl << endl;
						semError++;
						prblm = true;
					}
					//TBMF
					SymbolInfo *tmp2 = (new SymbolInfo())->setName($1->getName())->setIDType("ARA")->setIndex($3->intVal)->setVarType($1->getVarType());

					$$ = tmp2;

				}
				$$->stmt = $1->getName() + "["+$3->stmt + "]";
				$$->errorFound = prblm;
				logFile << $$->stmt << endl << endl;
			}
			;

			argument_list	: arguments{
				$$ = $1;
				logFile << "At line no: "<< line_count << " : argument_list : arguments\n"<< endl;
				logFile << $$->stmt << endl << endl;
			}
			|
			{
				$$ = new SymbolInfo();
				$$->stmt = "";
			}
			;

			arguments	:arguments COMMA logic_expression {
				logFile << "At line no: "<< line_count << " : arguments : arguments COMMA logic_expression\n"<< endl;
				$1->ParamList.push_back($3->getVarType());
				$$ = $1 ;
				$$->stmt = $1->stmt + "," + $3->stmt;
				logFile << $$->stmt << endl << endl;

			}
			|logic_expression {
				logFile << "At line no: "<< line_count << " : arguments : logic_expression\n"<< endl;
				SymbolInfo *tmp = new SymbolInfo();
				tmp->ParamList.push_back($1->getVarType());
				$$ =tmp;
				$$->stmt = $1->stmt;
				logFile << $$->stmt << endl << endl;
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
				errorFile.open("errors.txt");
				table.setStream(logFile);

				yyin = fp;
				yyparse();

				logFile<<"            Symbol Table"<<endl;
				table.printAll(logFile);
				logFile<<"Total Lines: "<<line_count<<endl<<endl;
				logFile<<"Total Errors: "<<semError<<endl<<endl;
				errorFile<<"Total Errors: "<<semError<<endl<<endl;
				logFile.close();
				errorFile.close();

				exit(0);
				return 0;
			}
