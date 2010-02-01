//desc:test LString is used as a return type of a non-leaving operator function for LS13
//option:
//date:2008-8-21 14:10:2
//author:pingorliu
//type: CT

class temp
{
	public:
LStringXX operator+(TInt x) //check:return,LString
{
	foo();
}
};
