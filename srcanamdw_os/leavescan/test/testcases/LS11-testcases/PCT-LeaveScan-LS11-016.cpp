//desc: test LCleanedup is used to declare a local variable of a operator function of a common class
//option:
//date:2008-8-20 13:51:31
//author:pingorliu
//type: CT

class temp
{
	private:
               TInt operator+(temp& t)
	       {
                LCleanedup member; //check:LCleanedup,operator+
	       }
};
