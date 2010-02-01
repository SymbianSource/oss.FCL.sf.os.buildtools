//desc:test LCleanup class used in specialised template function for LS12
//option:
//date:2008-8-12 15:58:1
//author:pingorliu
//type: CT

template<class T>
void func()
{


}
template<>
void func<TInt>()
{
LData<T> baz;//check:LData

}
