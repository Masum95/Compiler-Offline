#ifndef SYMBOLTABLE_H_INCLUDED
#define SYMBOLTABLE_H_INCLUDED



#endif // SYMBOLTABLE_H_INCLUDED

#include<bits/stdc++.h>
#include "ScopeTable.h"
#define infile freopen("in.txt","r",stdin)
#define outfile freopen("out.txt","w",stdout)

#define nl printf("\n")
#define bug   cout<<"bug"<<endl;

using namespace std;

/*
bool equalIgnoreCase(string str1,string str2)
{
if(str1.length()!=str2.length()) return false;
int i = 0;
while(i<str1.length())
{
if(tolower(str1[i])!=tolower(str2[i])) return false;
i++;
}

return true;
}
*/

class SymbolTable
{
  ofstream LogFile;
public:
  int buckSize, scopeNum , scopeNumShow;
  vector<ScopeTable*> st;
  ScopeTable *cur;
  SymbolTable(int sz)
  {
    buckSize = sz;
    scopeNum = 0 , scopeNumShow = 1;
    cur = new ScopeTable(sz,scopeNum+1,NULL);
    st.push_back(cur);
  }

  void setStream(ofstream &logFile)
  {
    LogFile.copyfmt(logFile);                                  //1
    LogFile.clear(logFile.rdstate());
    LogFile.basic_ios<char>::rdbuf(logFile.rdbuf());
  }

  bool insert(SymbolInfo *sym)
  {
    cur->insert(sym);

  }

  SymbolInfo* lookUpInScopes(SymbolInfo *sym)
  {
    SymbolInfo *tmp = NULL;
    for(int i=st.size()-1; i>=0; i--)
    {
      tmp = st[i]->lookupWithIDType(sym);
      if(tmp!=NULL) return tmp;
    }

    return tmp;
  }

  SymbolInfo* lookUpInCurScope(SymbolInfo *sym)
  {
    return cur->lookupWithIDType(sym);
  }
  bool deleteElement(SymbolInfo *sym)
  {
    cur->Delete(sym);
  }
  void printAll(ofstream &logFile)
  {

    for(int i=st.size()-1; i>=0; i--)
    {

      st[i]->print(LogFile);
    }
  }
  void printCurScope(ofstream &logFile)
  {
    cur->print(LogFile);
  }
  void enterScope()
  {
    scopeNum++; scopeNumShow++;
    cur = new ScopeTable(buckSize,scopeNumShow,st[scopeNum-1]);
    LogFile<<" New ScopeTable with id "<<scopeNumShow<<" created"<<endl;
    st.push_back(cur);
  }

  void exitScope()
  {
    if(st.size()>1)
    {
      delete st.back();
      st.pop_back();

      cur = st.back();

      LogFile<<" ScopeTable with id "<<scopeNumShow<<" removed "<<endl;
      scopeNum--;
      //printf("ScopeTable with id %d removed\n",scopeNum);
    }
  }


};
