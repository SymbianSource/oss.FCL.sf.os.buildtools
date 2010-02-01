//desc: test LCleanedup is used to declare a static data member of a nested class
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
                const static LCleanedup member; //check:LCleanedup,data,member
};
};
