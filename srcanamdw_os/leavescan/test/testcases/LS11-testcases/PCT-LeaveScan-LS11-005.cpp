//desc: test LCleanedup is used to declare a common data member of a class that has no name
//option:
//date:2008-8-20 13:51:31
//author:pingorliu
//type: CT

struct
{
	private:
                LCleanedupPtr<TInt> member; //check:LCleanedup,data,member
} mystruct;
