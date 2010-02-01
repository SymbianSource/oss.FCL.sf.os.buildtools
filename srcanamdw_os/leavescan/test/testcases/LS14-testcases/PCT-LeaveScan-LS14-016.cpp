//desc:test LString is used as a parameter of a overload leaving function for LS14
//option:
//date:2008-8-21 14:10:2
//author:pingorliu
//type: CT

const TInt funcLX(TInt x) 
{
	foo();
}
const TInt funcLX(const LString16) //check:-func,-parameter
{
	foo();
}
