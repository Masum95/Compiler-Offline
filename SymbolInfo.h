#ifndef SYMBOLINFO_H_INCLUDED
#define SYMBOLINFO_H_INCLUDED



#endif // SYMBOLINFO_H_INCLUDED


#include<bits/stdc++.h>

using namespace std;
class SymbolInfo
{
    string name,type;

public:
    SymbolInfo *ptr;
    SymbolInfo()
    {
        name = "", type = "" ;
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
    string getName()
    {
        return name;
    }
    string getType()
    {
        return type;
    }

    void print()
    {
        cout<<"< "<<type<<" : "<<name<<" > ";
    }
};

