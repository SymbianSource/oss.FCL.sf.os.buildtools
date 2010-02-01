//desc: test LCleanedup is used to declare a common data member of a inherit class
//option:
//date:2008-8-20 13:51:31
//author:pingorliu
//type: CT

class base
{
};
class base2
{
};
struct temp:public base,private base2
{
	private:
                LCleanedupPtr<TInt> member; //check:LCleanedup,data,member
};
