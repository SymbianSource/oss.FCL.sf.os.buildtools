//desc: test LCleanedup is used to declare a local variable of a virtual member function of a common struct
//option:
//date:2008-8-20 13:51:31
//author:pingorliu
//type: CT

struct temp
{
	private:
               virtual void func()
	       {
                static const LCleanedupPtr<TInt> member; //check:LCleanedup,func
	       }
};
