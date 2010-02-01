//desc:test LString is used as a parameter of a non-leaving operator function for LS14
//option:
//date:2008-8-21 14:10:2
//author:pingorliu
//type: CT

class temp
{
	public:
TInt operator+(LStringXX x) //check:parameter,LString
{
}
};
