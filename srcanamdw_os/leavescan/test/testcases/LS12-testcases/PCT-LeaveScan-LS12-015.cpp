//desc:test LManaged class used in specialised template function for LS12
//option:
//date:2008-8-12 15:58:1
//author:pingorliu
//type: CT

class temp
{
template<class T>
void func()
{


}
};

template<>
void temp::func<TInt>()
{
LManagedHandle<RFoo> foo;//check:LManaged
}
