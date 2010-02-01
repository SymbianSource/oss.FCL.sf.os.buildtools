//desc: test LCleanedup is used to declare a local variable of a constructor of a common class
//option:
//date:2008-8-20 13:51:31
//author:pingorliu
//type: CT

class temp
{
	private:
               temp(TInt x)
	       {
                static LCleanedup member; //check:LCleanedup,temp
	       }
};
