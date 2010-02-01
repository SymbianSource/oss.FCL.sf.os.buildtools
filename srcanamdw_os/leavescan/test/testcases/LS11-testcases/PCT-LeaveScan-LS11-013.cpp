//desc: test LCleanedup is used to declare a local variable of a common member function of a common struct
//option:
//date:2008-8-20 13:51:31
//author:pingorliu
//type: CT

struct temp
{
	private:
               void func()
	       {
                LCleanedupPtr<TInt> member; //check:LCleanedup,func
	       }
};
