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
	
    
    void executeCommand(char *ch)
    {
	string str(ch);
        if(st.size()==0) return;
        int i = 0;
        stringstream ss(str);
        vector<string> ara;
        string tmp;
        
        nl;
        while(ss>>tmp)
        {
            ara.push_back(tmp);
        }

        if(equalIgnoreCase(ara[0],"I"))
        {
            SymbolInfo *tmp = new SymbolInfo();
            tmp->setName(ara[1]) -> setType(ara[2]);

            cur->insert(tmp);
        }
        else if(equalIgnoreCase(ara[0],"L"))
        {
            SymbolInfo *tmp = NULL;
            int indx = st.size()-1;

            if(tmp==NULL && indx>=0)
            {
                tmp = st[indx]->lookup(ara[1]);
                indx--;
            }
            if(indx<0 && tmp==NULL)
            {
                printf("Not found\n");
            }
        }
        else if(equalIgnoreCase(ara[0],"D"))
        {
            cur->Delete(ara[1]);
        }
        else if(equalIgnoreCase(ara[0],"P"))
        {
            if(equalIgnoreCase(ara[1],"A"))
            {
                for(int i=st.size()-1; i>=0; i--)
                {
					
                    st[i]->print();
                }
            }
			
            else
            {
                cur->print();
            }
			
        }
        else if(equalIgnoreCase(ara[0],"S"))
        {
            cur = new ScopeTable(buckSize,++scopeNum,st[scopeNum-1]);
            st.push_back(cur);
            printf("New ScopeTable with id %d created\n",scopeNum);
        }
        else if(equalIgnoreCase(ara[0],"E"))
        {
            if(st.size()>1)
            {
                delete st.back();
                st.pop_back();

                cur = st.back();
                printf("ScopeTable with id %d removed\n",scopeNum);
                scopeNum--;
            }

        }
        else
        {
            printf("Unknown Command\n");
        }
    }

};



