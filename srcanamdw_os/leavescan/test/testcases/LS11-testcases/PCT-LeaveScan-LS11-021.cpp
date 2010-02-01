//desc: test LCleanedup is used to declare a local variable of a virtual member function of a nested class
//option:
//date:2008-8-20 13:51:31
//author:pingorliu
//type: CT

class base
{
	public:
struct temp
{
	private:
               virtual void func()
	       {
                static LCleanedupPtr<TInt> member; //check:LCleanedup,func
	       }
};
};
