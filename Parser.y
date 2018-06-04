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
	int syntaxError = 0;
	int semError = 0;
	string variable_type;
	vector<SymbolInfo*> params;
	vector<string> args;
	int argsWithId = 0;
	SymbolTable table(11);
	FILE *fp;
	ofstream logFile, errorFile;

	void yyerror(const char *s)
	{
		//write your code
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

	%type <symVal>type_specifier expression logic_expression rel_expression simple_expression term unary_expression factor variable argument_list arguments

	%nonassoc second_precedence
	%nonassoc ELSE
	%error-verbose

	%%

	start : program
	{
		logFile << "Line " << line_count << " : start : program\n"<< endl;
	}
	;

	program : program unit
	{
		logFile << "Line " << line_count << " : program : program unit\n"<< endl;

	}
	| unit
	{
		logFile << "Line " << line_count << " : program : unit\n"<< endl;
	}
	;

	unit : 	var_declaration
	{
		logFile << "Line " << line_count << " : unit : var_declaration\n"<< endl;
	}
	|
	func_declaration
	{
		logFile << "Line " << line_count << " : unit : func_declaration\n"<< endl;
	}
	|
	func_definition
	{
		logFile << "Line " << line_count << " : unit : func_definition\n"<< endl;
	}
	;

	func_declaration : type_specifier ID LPAREN parameter_list RPAREN SEMICOLON
	{
		logFile << "Line " << line_count << " : func_declaration : 	type_specifier ID LPAREN parameter_list RPAREN SEMICOLON\n";
		logFile << $2->getName() << endl << endl;
		bool isDeclared = table.lookUpInScopes((new SymbolInfo())->setName($2->getName())->setIDType( "FUNC") );
		if(isDeclared)
		{
			errorFile << "Error at line " << line_count << " Function "<< $2 <<" already declared" << endl << endl;
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
			table.insert(tmp);
			args.clear();
		}

	}
	|type_specifier ID LPAREN parameter_list RPAREN error
	{
		errorFile << "Error at line " << line_count << "; missing" << endl << endl;
		semError++;
	}
	;

	func_definition : type_specifier ID LPAREN parameter_list RPAREN compound_statement{
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
					errorFile << "Error at line " << line_count << "Function "<< $2->getName() <<" :return type doesn't match declaration" << endl << endl;
					semError++;

				}
				else if (tmp->ParamList.size()!=argsWithId )
				{
					errorFile << "Error at line " << line_count << "Function "<< $2->getName() <<" :Parameter list doesn not match declaration" << endl << endl;
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
	}
	;


	parameter_list  : parameter_list COMMA type_specifier ID
	{
		logFile << "Line " << line_count << " : parameter_list  : parameter_list COMMA type_specifier ID\n";
		logFile << $4->getName() << endl << endl;
		argsWithId++;
		args.push_back(variable_type);
		SymbolInfo *tmp = new SymbolInfo();
		tmp->setIDType("VAR")->setType("ID")->setVarType(variable_type);
		params.push_back(tmp);
	}
	| parameter_list COMMA type_specifier
	{
		logFile << "Line " << line_count << " : parameter_list  : parameter_list COMMA type_specifier\n"<< endl;
		args.push_back(variable_type);
	}
	| type_specifier ID
	{
		logFile << "Line " << line_count << " : parameter_list  : parameter_list COMMA type_specifier ID\n";
		logFile << $2->getName() << endl << endl;
		argsWithId++;
		args.push_back(variable_type);
		SymbolInfo *tmp = new SymbolInfo();
		tmp->setIDType("VAR")->setType("ID")->setVarType(variable_type);
		params.push_back(tmp);
	}
	| type_specifier
	{
		logFile << "Line " << line_count << " : parameter_list  : type_specifier\n"<< endl;
		args.push_back(variable_type);
	}
	| /*EMPTY */
	;


	compound_statement : LCURL
	{
		table.enterScope();
		for(int i=0;i<params.size();i++)
		{
			table.insert(params[i]);
		}
		params.clear();
		} statements
		{
			table.printAll(logFile);
			} RCURL
			{
				table.exitScope();
			}
			| LCURL RCURL { logFile << "Line " << line_count << " : compound_statement : LCURL RCURL\n"<< endl; }
			;

			var_declaration : type_specifier declaration_list SEMICOLON {
				logFile << "Line " << line_count << " : var_declaration : type_specifier declaration_list SEMICOLON\n"<< endl;
			}
			|type_specifier declaration_list error
			{
				errorFile << "Error at line " << line_count << "; missing" << endl << endl;
				semError++;
			}
			;

			type_specifier	: INT
			{
				logFile << "Line " << line_count << " : type_specifier	: INT\n"<< endl;
				SymbolInfo* tmp= new SymbolInfo();
				tmp->setIDType("INT");
				variable_type = "INT";
				$$ = tmp;
			}
			| FLOAT
			{
				logFile << "Line " << line_count << " : type_specifier	: FLOAT\n"<< endl;
				SymbolInfo* tmp= new SymbolInfo();
				tmp->setIDType("INT");
				variable_type = "FLOAT";
				$$ = tmp;
			}
			| VOID
			{
				logFile << "Line " << line_count << " : type_specifier	: VOID\n"<< endl;
				SymbolInfo* tmp= new SymbolInfo();
				tmp->setIDType("INT");
				variable_type = "VOID";
				$$ = tmp;
			}
			;

			declaration_list : declaration_list COMMA ID
			{
				logFile << "Line " << line_count << " : declaration_list : 	declaration_list COMMA ID\n";
				logFile << $3->getName() << endl << endl;
				if(variable_type == "VOID"){
					errorFile << "Error at line " << line_count << " :variable type can't be void" << endl << endl;
					semError++;
				}
				else{
					SymbolInfo *tmp = table.lookUpInScopes((new SymbolInfo())->setName($3->getName())->setIDType("VAR"));
					//Is it declared earlier as different or same idType ?
					if(tmp==NULL)
					{
						SymbolInfo* tmp2 = new SymbolInfo();
						tmp2->setName($3->getName())->setIDType("VAR")->setVarType(variable_type);
						table.insert(tmp);
					}
					else{
						errorFile << "Error at line " << line_count << ": Variable "<< $3->getName() <<" already declared" << endl << endl;
						semError++;
					}
				}
			}
			| declaration_list COMMA ID LTHIRD CONST_INT RTHIRD
			{
				logFile << "Line " << line_count << " : declaration_list : 	declaration_list COMMA ID LTHIRD CONST_INT RTHIRD\n";
				logFile << $3->getName() << endl;
				logFile << $5->getName() << endl << endl;
				if(variable_type == "VOID"){
					errorFile << "Error at line " << line_count << " : array type can't be void" << endl << endl;
					semError++;
				}
				else{
					SymbolInfo *tmp = table.lookUpInScopes((new SymbolInfo())->setName($3->getName())->setIDType("ARA"));
					if(tmp!=NULL)
					{
						errorFile << "Error at line " << line_count << ": Variable "<< $3->getName() <<" already declared" << endl << endl;
						semError++;
					}
					else{
						SymbolInfo *tmp2 = new SymbolInfo();
						tmp2->setName($3->getName())->setIDType("ARA");
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
						table.insert(tmp2);

					}
				}
			}
			| ID
			{
				logFile << "Line " << line_count << " : declaration_list :	ID\n";
				logFile << $1->getName() << endl << endl;
				if(variable_type == "VOID"){
					errorFile << "Error at line " << line_count << " :variable type can't be void" << endl << endl;
					semError++;
				}
				else{
					SymbolInfo *tmp = table.lookUpInScopes((new SymbolInfo())->setName($1->getName())->setIDType("VAR"));
					//Is it declared earlier as different or same idType ?
					if(tmp==NULL)
					{
						SymbolInfo* tmp2 = new SymbolInfo();
						tmp2->setName($1->getName())->setIDType("VAR")->setVarType(variable_type);
						table.insert(tmp);
					}
					else{
						errorFile << "Error at line " << line_count << ": Variable "<< $1->getName() <<" already declared" << endl << endl;
						semError++;
					}
				}
			}
			| ID LTHIRD CONST_INT RTHIRD
			{
				logFile << "Line " << line_count << " : declaration_list :	ID LTHIRD CONST_INT RTHIRD\n";
				logFile << $1->getName() << endl;
				logFile << $3->getName() << endl << endl;
				if(variable_type == "VOID"){
					errorFile << "Error at line " << line_count << " : array type can't be void" << endl << endl;
					semError++;
				}
				else{
					SymbolInfo *tmp = table.lookUpInScopes((new SymbolInfo())->setName($3->getName())->setIDType("ARA"));
					if(tmp!=NULL)
					{
						errorFile << "Error at line " << line_count << ": Variable "<< $1->getName() <<" already declared" << endl << endl;
						semError++;
					}
					else{
						SymbolInfo *tmp2 = new SymbolInfo();
						tmp2->setName($1->getName())->setIDType("ARA");
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

			statements : statement{logFile << "Line " << line_count << " : statements : statement\n"<< endl;}
			| statements statement{logFile << "Line " << line_count << " : statements : statements statement\n"<< endl;}
			;


			statement : var_declaration{logFile << "Line " << line_count << " : statement : var_declaration\n"<< endl;}
			| expression_statement{logFile << "Line " << line_count << " : statement : expression_statement\n"<< endl;}
			| compound_statement{logFile << "Line " << line_count << " : statement : compound_statement\n"<< endl;}
			| FOR LPAREN expression_statement expression_statement expression RPAREN statement
			{logFile << "Line " << line_count << " : statement : FOR LPAREN expression_statement expression_statement expression RPAREN statement\n"<< endl;}
			| IF LPAREN expression RPAREN statement /* %prec second_precedence ............ to be added later */
			{logFile << "Line " << line_count << " : statement : IF LPAREN expression RPAREN statement\n"<< endl;}
			| IF LPAREN expression RPAREN statement ELSE statement
			{logFile << "Line " << line_count << " : statement : IF LPAREN expression RPAREN statement ELSE statement\n"<< endl;}
			| WHILE LPAREN expression RPAREN statement{logFile << "Line " << line_count << " : statement : WHILE LPAREN expression RPAREN statement\n"<< endl;}
			| PRINTLN LPAREN ID RPAREN SEMICOLON{logFile << "Line " << line_count << " : statement : PRINTLN LPAREN ID RPAREN SEMICOLON\n"<< endl;}
			| PRINTLN LPAREN ID RPAREN error
			{
				errorFile << "Error at line " << line_count << "; missing" << endl << endl;
				semError++;
			}
			| RETURN expression SEMICOLON{logFile << "Line " << line_count << " : statement : RETURN expression SEMICOLON\n"<< endl;}
			|RETURN expression error
			{
				errorFile << "Error at line " << line_count << "; missing" << endl << endl;
				semError++;
			}
			;

			expression_statement 	: SEMICOLON{logFile << "Line " << line_count << " : expression_statement : SEMICOLON\n"<< endl;}
			| expression SEMICOLON {logFile << "Line " << line_count << " : expression_statement : expression SEMICOLON\n"<< endl;}
			|expression error
			{
				errorFile << "Error at line " << line_count << "; missing" << endl << endl;
				semError++;
			}
			;

			variable : ID
			{
				logFile << "Line " << line_count << " : variable : ID\n";
				logFile << $1->getName() << endl << endl;
				SymbolInfo *tmp = table.lookUpInScopes((new SymbolInfo())->setName($1->getName())->setIDType("VAR"));
				if(tmp==NULL)
				{
					errorFile << "Error at line " << line_count << " : " << $1->getName() << " doesn't exist" <<  endl << endl;
					semError++;
				}
				else{
					$$ = tmp;
				}
			}
			| ID LTHIRD expression RTHIRD /* ara variable */
			{
				logFile << "Line " << line_count << " : variable : ID LTHIRD expression RTHIRD\n";
				logFile << $1->getName() << endl << endl;
				SymbolInfo *tmp = table.lookUpInScopes((new SymbolInfo())->setName($1->getName())->setIDType("ARA"));
				if(tmp==NULL)
				{
					errorFile << "Error at line " << line_count << " : " << $1->getName() << " doesn't exist" <<  endl << endl;
					semError++;
				}
				else{
					if($3->getVarType()=="FLOAT")
					{
						errorFile << "Error at line " << line_count << " : " << " invalid types for array subscript " <<  endl << endl;
						semError++;
					}
				}
				if($3->intVal >= tmp->getAraSize())
				{
					errorFile << "Error at line " << line_count << " : " <<$1->getName() << " array index out of bounds" <<  endl << endl;
					semError++;
				}
				//TBMF
				tmp->setIndex($3->intVal);
				$$ = tmp;
			}
			;

			expression : logic_expression
			{
				logFile << "Line " << line_count << " : expression : logic_expression\n"<< endl;
				$$ = $1;
				//TBMF
			}
			| variable ASSIGNOP logic_expression
			{
				logFile << "Line " << line_count << " : expression : variable ASSIGNOP logic_expression\n"<< endl;
				string vType = $1->getVarType();
				if($1->getIDType()=="VAR")
				{
					if($3->getIDType()=="VAR") $1->setValue($3->getValue());
					if($3->getIDType()=="ARA")$1->setValue($3->getAraElementValue($3->getIndex()));
				}
				else{ // if araType
					if($3->getIDType()=="VAR")$1->setAraElementValue($1->getIndex(), $3->getValue());
					if($3->getIDType()=="ARA")$1->setAraElementValue($1->getIndex(), $3->getAraElementValue($3->getIndex()));
				}
				$$ = $1;
				//-----------Table to be printed ----
			}
			;

			logic_expression : rel_expression
			{
				logFile << "Line " << line_count << " : logic_expression : rel_expression\n"<< endl;
				$$ = $1;
				//TBMF
			}
			| rel_expression LOGICOP rel_expression
			{
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

			}
			;

			rel_expression	: simple_expression
			{
				logFile << "Line " << line_count << " : rel_expression : simple_expression\n"<< endl;
				$$ = $1;
			}
			| simple_expression RELOP simple_expression
			{
				string relop = $2->getName();
				int ans;
				logFile << "Line " << line_count << " : rel_expression : simple_expression RELOP simple_expression\n"<< endl;
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
				$$ = temp;
			}
			;

			simple_expression : term
			{
				logFile << "Line " << line_count << " : simple_expression : term\n"<< endl;
				$$ = $1;
			}
			| simple_expression ADDOP term
			{
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
			}
			;

			term :	unary_expression
			{
				logFile << "Line " << line_count << " : term : unary_expression\n"<< endl;
				$$ = $1;
			}
			|  term MULOP unary_expression
			{
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
						semError++;
					}
					else if(varType1 !="INT" && varType2!="INT") ans =  ( (int) val1 ) / ( (int) val2 );
					else ans = val1 / val2;
				}
				if($2->getName() == "%")
				{
					if(varType1=="FLOAT" || varType2=="FLOAT")
					{
						errorFile << "Error at line " << line_count <<" : Unsuported operand for mod operator"<<endl << endl;
						semError++;
					}
					if(val2==0)
					{
						errorFile << "Error at line " << line_count <<" : MOD by zero"<<endl << endl;
						semError++;
					}
					else ans = (int)val1 % (int)val2;
				}
				tmp->setValue(ans);
				$$ = tmp;
			}
			;

			unary_expression : ADDOP unary_expression
			{
				logFile << "Line " << line_count << " : unary_expression : ADDOP unary_expression\n"<< endl;
				if($1->getName() == "-"){
					if($2->getVarType() == "VAR"){
						$2->setValue(-1*($2->getValue()));
					}
					else if($2->getVarType() == "ARA"){
						$2->setAraElementValue($2->getIndex(),-1*($2->getAraElementValue($2->getIndex())));
					}
				}
				$$ = $2;
			}
			| NOT unary_expression
			{
				logFile << "Line " << line_count << " : unary_expression : NOT unary_expressionn"<< endl;
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
			}
			| factor
			{
				logFile << "Line " << line_count << " : unary_expression : factor\n"<< endl;
				$$ = $1;
			}
			;

			factor	: variable
			{
				logFile << "Line " << line_count << " : factor : variable\n"<< endl;
				$$ = $1;
			}
			| ID LPAREN argument_list RPAREN
			{
				logFile << "Line " << line_count << " : factor : ID LPAREN argument_list RPAREN\n";
				logFile << $1->getName() << endl << endl;
				SymbolInfo *temp=new SymbolInfo();

				temp = table.lookUpInScopes((new SymbolInfo())->setName($1->getName())->setIDType( "FUNC") );
				if(temp == NULL){
					errorFile << "Error at line " << line_count <<" : Function " <<$1->getName() <<" doesn't exist"<<endl << endl;
				}
					else{
						int sz = $1->ParamList.size();
						if(sz > $3->ParamList.size())
						{
							errorFile << "Error at line " << line_count <<"  : Function " <<$1->getName() <<" too few arguments"<<endl << endl;
						}
						else if(sz < $3->ParamList.size())
						{
							errorFile << "Error at line " << line_count <<"  : Function " <<$1->getName() <<" too many arguments"<<endl << endl;
						}
						else{
							SymbolInfo *tmp2 = (new SymbolInfo())->setVarType($1->getFuncRetType());
							$$ = tmp2;
						}
					}
				}
				| LPAREN expression RPAREN
				{
					logFile << "Line " << line_count << " : factor : LPAREN expression RPAREN\n"<< endl;
					$$ = $2;
				}
				| CONST_INT{
					logFile << "Line " << line_count << " : factor : CONST_INT\n";
					logFile << $1->getName() << endl << endl;
					$1->setVarType("INT")->setIDType("VAR");
					$1->setValue(atoi($1->getName().c_str()));
					$$ = $1;
				}
				| CONST_FLOAT
				{
					logFile << "Line " << line_count << " : factor : CONST_FLOAT\n";
					logFile << $1->getName() << endl << endl;
					$1->setVarType("FLOAT")->setIDType("VAR");
					$1->setValue(atof($1->getName().c_str()));
					$$ = $1;
				}
				| variable INCOP
				{
					if($1->getIDType() == "VAR"){
						$1->setValue($1->getValue()+1);
					}
					else if($1->getIDType() == "ARA"){
						$1->setAraElementValue($1->getIndex(),$1->getAraElementValue($1->getIndex())+1);
					}

				}
				| variable DECOP
				{
					if($1->getIDType() == "VAR"){
						$1->setValue($1->getValue()-1);
					}
					else if($1->getIDType() == "ARA"){
						$1->setAraElementValue($1->getIndex(),$1->getAraElementValue($1->getIndex())-1);
					}
				}
				;

				argument_list	: arguments{
					$$ = $1;
					logFile << "Line " << line_count << " : argument_list : arguments\n"<< endl;
				}
				|
				;

				arguments	:arguments COMMA logic_expression {
					logFile << "Line " << line_count << " : arguments : arguments COMMA logic_expression\n"<< endl;
					$1->ParamList.push_back($3->getVarType());
					$$ = $1;
				}
				|logic_expression {
					logFile << "Line " << line_count << " : arguments : logic_expression\n"<< endl;
					SymbolInfo *tmp = new SymbolInfo();
					tmp->ParamList.push_back($1->getVarType());
					$$ =tmp;
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


					yyparse();


					logFile.close();
					errorFile.close();


					return 0;
				}
