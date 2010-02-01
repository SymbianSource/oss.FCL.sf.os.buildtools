//desc:test LString is used as a return type of a non-leaving member function that defined out of the class for LS13
//option:
//date:2008-8-21 14:10:2
//author:pingorliu
//type: CT

class temp
{
	public:
LString16 func(); //check:func,return,LString
};

LString16 temp::func()//check:func,return,LString
{
	fooL();
}
