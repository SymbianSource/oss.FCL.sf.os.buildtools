//desc: test LCleanedup is used to declare a local variable of a destructor of a common class
//option:
//date:2008-8-20 13:51:31
//author:pingorliu
//type: CT

class temp
{
	private:
               ~temp()
	       {
                static LCleanedup member; //check:LCleanedup,~temp
	       }
};