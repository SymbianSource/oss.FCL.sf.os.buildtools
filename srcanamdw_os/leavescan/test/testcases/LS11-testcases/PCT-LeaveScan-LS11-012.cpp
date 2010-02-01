//desc: test LCleanedup is used to declare a static data member of a template class
//option:
//date:2008-8-20 13:51:31
//author:pingorliu
//type: CT

template<class Type>
class base
{
};
template<class T>
class temp:public base<TInt>
{
	private:
                static LCleanedupBuf<T> member; //check:LCleanedup,data,member
};
