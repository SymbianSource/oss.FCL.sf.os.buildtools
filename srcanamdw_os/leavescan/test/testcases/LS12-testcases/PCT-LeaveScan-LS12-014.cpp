//desc:test LManaged class used in template function for LS12
//option:
//date:2008-8-12 15:58:1
//author:pingorliu
//type: CT

class temp
{
template<class T>
void func()
{
LManagedHandle<RFoo> foo;//check:LManaged

}
};
