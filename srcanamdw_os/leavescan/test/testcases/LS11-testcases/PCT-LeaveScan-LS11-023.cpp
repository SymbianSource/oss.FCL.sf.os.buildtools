//desc: test LCleanedup is used to declare a local variable of a overload function of a template class
//option:
//date:2008-8-20 13:51:31
//author:pingorliu
//type: CT

template<class T>
class base
{
};
template<class TT>
struct temp:private base<TInt>
{
	private:
	       virtual void func(TInt,TEXT)
	       {
	       }
               virtual void func(TT b)
	       {
                static LCleanedupPtr<TT> member; //check:LCleanedup,func
	       }
}my;
