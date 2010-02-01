//desc: test LCleanedup is used to declare a local variable of a virtual operator function of a non-name class
//option:
//date:2008-8-20 13:51:31
//author:pingorliu
//type: CT

class base
{
};
struct 
{
	private:
               virtual TInt operator+(base b)
	       {
                static LCleanedupPtr<TInt> member; //check:LCleanedup,operator+
	       }
} mystruct;
