//desc: test LCleanedup is used to declare a local variable of a common function of a inner class
//option:
//date:2008-8-20 13:51:31
//author:pingorliu
//type: CT

void func()
{
class temp
{
	private:
		void func()
		{
                LCleanedupBuf member; //check:LCleanedup,func
		}
};
}

