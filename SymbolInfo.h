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
  int araSize;
public:
  int intVal,scpNum;
  float floatVal;
  char chVal;
  string indx;
  string stmt,code,icgName,writeData,postCode;

  SymbolInfo *ptr;
  vector<string> ParamList;	//INT, FLOAT, STRING, CHAR
  vector<string> ParamVal;
  vector<int> ints;
  vector<float> floats;
  vector<char> chars;
  bool funcDefined,funcDeclared;
  bool errorFound;
  SymbolInfo()
  {
    name = "", type = "" ;
    funcDefined = false , errorFound = false;
    ptr = NULL;
  }


  SymbolInfo(string name,string type)
  {
    this->icgName = name;
    this-> name = name;
    this->type = type;
    ptr = NULL;
  }
  SymbolInfo* setName(string name)
  {
    this->name = this->icgName =  name;
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

  SymbolInfo* setAraSize(int num)
  {
    this->araSize = num;
    if(varType=="INT")
    {
      for(int i=0;i<num;i++)
      {
        ints.push_back(0);
      }

    }
    if(varType=="FLOAT")
    {
      for(int i=0;i<num;i++)
      {
        floats.push_back(0);
      }
    }
    if(varType=="CHAR")
    {
      for(int i=0;i<num;i++)
      {
        chars.push_back('\0');
      }
    }
    return this;
  }

  SymbolInfo* setIndex(string num)
  {
    this->indx= num;
    return this;
  }

  SymbolInfo* copyObject(SymbolInfo *tmp)
  {
    varType = tmp->varType , idType = tmp->idType , name = tmp->name , icgName = tmp->icgName;
    ParamList = tmp->ParamList , ParamVal = tmp->ParamVal , postCode = tmp->postCode , funcRetType = tmp->funcRetType;
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


  void setValue(double a){

    if(varType=="INT") intVal = a;
    if(varType=="FLOAT") floatVal = a;
    if(varType=="CHAR") chVal = a;

  }



  double getValue(){
    if(varType=="INT") return intVal;
    if(varType=="FLOAT") return floatVal;
    if(varType=="CHAR") return chVal;
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

  int getAraSize()
  {
    return araSize;
  }

  string getIndex()
  {
    return indx;
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


  void print(ofstream &logFile)
  {
    logFile<<"< "<<name<<" : "<<idType<<" > ";
    //logFile<<"< "<<name<<" : "<<type<<" : "<<idType<<" > ";
  }
};
