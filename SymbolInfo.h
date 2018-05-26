#ifndef SYMBOLINFO_H_INCLUDED
#define SYMBOLINFO_H_INCLUDED



#endif // SYMBOLINFO_H_INCLUDED


#include<bits/stdc++.h>

using namespace std;
class SymbolInfo
{
  string name,type; // type contains whether ID,RELOP or ADDOP etc. Information
  string idType;  // Function , Ara  , VAR
  string varType; // int , float , string
  string funcRetType;
public:
  int intVal;
  float floatVal;
  char chVal;
  SymbolInfo *ptr;
  vector<string> ParamList;	//INT, FLOAT, STRING, CHAR
  vector<int> ints;
  vector<float> floats;
  vector<char> chars;
  bool funcDefined;
  SymbolInfo()
  {
    name = "", type = "" ;
    funcDefined = false;
    ptr = NULL;
  }

  SymbolInfo(string name,string type)
  {

    this-> name = name, this->type = type;
    ptr = NULL;
  }
  SymbolInfo* setName(string name)
  {
    this->name = name;
    return this;
  }
  SymbolInfo* setType(string type)
  {
    this->type = type;
    return this;
  }
  SymbolInfo* setIDType(string type)
  {
    this->idType = type;
    return this;
  }
  SymbolInfo* setVarType(string type)
  {
    this->varType = type;
    return this;
  }

  SymbolInfo* setFuncRetType(string type)
  {
    this->funcRetType = type;
    return this;
  }
  void setFunctionDefined(){
    funcDefined = true;
  }
  string getName()
  {
    return name;
  }
  string getType()
  {
    return type;
  }
  string getIDType()
  {
    return idType;
  }

  string getVarType()
  {
    return varType;
  }

  string getFuncRetType()
  {
    return funcRetType;
  }

  bool isFuncDefined(){
    return funcDefined;
  }


  void print()
  {
    cout<<"< "<<type<<" : "<<name<<" > ";
  }
};
