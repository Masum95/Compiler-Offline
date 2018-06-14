#ifndef SCOPETABLE_H_INCLUDED
#define SCOPETABLE_H_INCLUDED



#endif // SCOPETABLE_H_INCLUDED


#include<bits/stdc++.h>
#include "SymbolInfo.h"
#define nl printf("\n")
#define bug   cout<<"bug"<<endl;

using namespace std;


class ScopeTable
{
public:
  SymbolInfo **buckets;
  int bucketSize,tableId;
  ScopeTable *parent;
  ScopeTable()
  {
    parent = NULL;
  }

  ScopeTable(int buckSize,int tid,ScopeTable *par)
  {
    parent = par;
    bucketSize = buckSize, tableId = tid;
    buckets = new SymbolInfo*[buckSize];
    for(int i=0; i<buckSize; i++) buckets[i] = NULL;
  }
  ~ScopeTable()
  {
    for(int i=0; i<bucketSize; i++)
    {

      if(buckets[i]!=NULL)
      {

        delete buckets[i];
      }
    }
    delete[] buckets;
  }

  int hashing(string str)
  {
    int prm = 29, i = 0;
    long long int val = 0;
    //cout<<str<<endl;
    while(i<str.length())
    {
      val+= prm* str[i];
      prm*=i;
      val%=bucketSize;
      i++;
    }
    //cout<<str<<"----"<<val%bucketSize<<endl;
    return val%bucketSize;
  }

  int hashing(SymbolInfo *sym)
  {
    string str = sym->getName();
    int prm = 11, i = 0;
    long long int val = 0;
    while(i<str.length())
    {
      val+= prm* str[i];
      prm*=i;
      val%=bucketSize;
      i++;
    }
    return val%bucketSize;
  }

  bool insert(SymbolInfo *nd)
  {
    int indx = hashing(nd->getName());
    int i = 0;
    SymbolInfo *tmp;
    if(buckets[indx]==NULL)
    {
      buckets[indx] = new SymbolInfo();
    }
    tmp = buckets[indx];
    while(tmp->ptr!=NULL)
    {
      tmp = tmp->ptr;

      i++;
    }

    tmp->ptr = nd;

    //printf("Inserted in ScopeTable# %d at position %d, %d\n",tableId,indx,i);
    return true;
  }

  SymbolInfo* lookupWithIDType(SymbolInfo *sym)
  {
    int i = 0;
    int indx = hashing(sym->getName());
    if(buckets[indx] == NULL)
    {
      return NULL;
    }
    SymbolInfo *tr = buckets[indx]->ptr;
    while(tr!=NULL)
    {
      if(tr->getName()==sym->getName() )
      {
        //printf("Found in ScopeTable# %d at position %d, %d\n",tableId,indx,i);
        return tr;
      }
      tr = tr->ptr;
      i++;
    }

    return NULL;
  }


  void print(ofstream &logFile)
  {
    logFile<<" ScopeTable # "<<tableId<<endl;
    //printf(" ScopeTable # %d\n",tableId);
    for(int i=0; i<bucketSize; i++)
    {

      if(buckets[i]==NULL)
      {
        continue;
      }
      logFile<<i<<" -->";
      // printf("%d -->",i);
      SymbolInfo *tr = buckets[i]->ptr;
      while(tr!=NULL)
      {
        tr->print(logFile);
        tr = tr->ptr;
      }
      logFile<<endl;
    }
  }
  bool Delete(SymbolInfo *sym)
  {
    string str = sym->getName();
    int i = 0;
    int indx = hashing(str);
    if(buckets[indx] == NULL)
    {
      //printf("Not found\n");
      return false;
    }
    SymbolInfo *tr = buckets[indx]->ptr,*pr = buckets[indx];
    while(tr!=NULL)
    {
      if(tr->getName()==str)
      {
        //  printf("Found in ScopeTable# %d at position %d, %d\n",tableId,indx,i);
        //  printf("Deleted entry at %d, %d from current ScopeTable\n",indx,i);
        pr->ptr = tr->ptr;
        delete tr;
        return true;
      }
      pr = tr;
      tr = tr->ptr;
      i++;
    }

    //  printf("Not found");
    //  nl;
    return false;


  }

};
