//desc:test LManaged class used in destructor function for LS12
//option:
//date:2008-8-12 15:58:1
//author:pingorliu
//type: CT

class temp
{

~temp()
{
LManagedHandle<RFoo> foo;//check:LManaged

}
};
