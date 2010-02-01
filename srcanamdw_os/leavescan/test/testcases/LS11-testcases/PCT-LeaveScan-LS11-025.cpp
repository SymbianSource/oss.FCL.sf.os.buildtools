//desc: test LCleanedup is used to declare a data member of a common function of a specialised class
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
                
} mystruct;

template<>
struct temp<TInt>:private base<TInt>
{
	private:
		void func()
		{
		static LCleanedupPtr<TT> member; //check:LCleanedup,func
		}

};
