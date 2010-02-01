//desc: test LCleanedup is used to declare a local variable of a type cast function of a common class
//option:
//date:2008-8-20 13:51:31
//author:pingorliu
//type: CT

class temp
{
	private:
               operator int()
	       {
                LCleanedup member; //check:LCleanedup,int
	       }
};
