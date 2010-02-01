//desc: test LCleanedup is used to declare a common data member of a nested class
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
                LCleanedup member; //check:LCleanedup,data,member
};
};
