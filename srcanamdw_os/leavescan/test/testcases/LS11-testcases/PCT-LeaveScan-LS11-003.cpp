//desc: test LCleanedup is used to declare a common data member of a inner class
//option:
//date:2008-8-20 13:51:31
//author:pingorliu
//type: CT

void func()
{
class temp
{
	private:
                LCleanedupBuf member; //check:LCleanedup,data,member
};
}
