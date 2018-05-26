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
public:
  int buckSize, scopeNum;
  vector<ScopeTable*> st;
  ScopeTable *cur;
  SymbolTable(int sz)
  {
    buckSize = sz;
    scopeNum = 1;
    cur = new ScopeTable(sz,1,NULL);
    st.push_back(cur);
  }
  bool insert(SymbolInfo *sym)
  {
    cur->insert(sym);
  }

  SymbolInfo* lookUpInScopes(SymbolInfo *sym)
  {
    SymbolInfo *tmp = NULL;
    int indx = st.size()-1;

    if(tmp==NULL && indx>=0)
    {
      tmp = st[indx]->lookupWithIDType(sym);
      indx--;
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
  void printAll()
  {

    for(int i=st.size()-1; i>=0; i--)
    {

      st[i]->print();
    }
  }
  void printCurScope()
  {
    cur->print();
  }
  void enterScope()
  {
    cur = new ScopeTable(buckSize,++scopeNum,st[scopeNum-1]);
    st.push_back(cur);
  }

  void exitScope()
  {
    if(st.size()>1)
    {
      delete st.back();
      st.pop_back();

      cur = st.back();
      //printf("ScopeTable with id %d removed\n",scopeNum);
      scopeNum--;
    }
  }


};
