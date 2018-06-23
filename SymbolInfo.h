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
  int intVal;
  float floatVal;
  char chVal;
  int indx;
  string stmt;

  SymbolInfo *ptr;
  vector<string> ParamList;	//INT, FLOAT, STRING, CHAR
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

    this-> name = name;
    this->type = type;
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

  SymbolInfo* setAraSize(int num)
  {
    this->araSize = num;
    return this;
  }

  SymbolInfo* setIndex(int num)
  {
    this->indx= num;
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

  void setAraElementValue(int indx,double a){
    if(varType=="INT") ints[indx] = a;
    if(varType=="FLOAT") floats[indx] = a;
    if(varType=="CHAR") chars[indx] = a;
  }

  double getValue(){
    if(varType=="INT") return intVal;
    if(varType=="FLOAT") return floatVal;
    if(varType=="CHAR") return chVal;
  }

  double getAraElementValue(int indx){
    if(varType=="INT") return ints[indx];
    if(varType=="FLOAT") return floats[indx];
    if(varType=="CHAR") return chars[indx];
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

  int getIndex()
  {
    return araSize;
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
    logFile<<"< "<<name<<" : "<<type<<" > ";
    //logFile<<"< "<<name<<" : "<<type<<" : "<<idType<<" > ";
  }
};
