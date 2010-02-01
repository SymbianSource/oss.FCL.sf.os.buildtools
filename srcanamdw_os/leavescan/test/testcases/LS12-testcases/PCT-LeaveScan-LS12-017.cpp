//desc:test LManaged class used in operator function for LS12
//option:
//date:2008-8-12 15:58:1
//author:pingorliu
//type: CT

class temp
{

TInt operator +(TInt x)
{
LManagedHandle<RFoo> foo;//check:LManaged

}
};
