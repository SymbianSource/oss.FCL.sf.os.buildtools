//desc:test LString is used as a parameter of a overload function for LS14
//option:
//date:2008-8-21 14:10:2
//author:pingorliu
//type: CT

void func(TInt x,const LString16 y) 
{
	foo();
}
void func(const LString16 x) //check:func,parameter
{
	foo();
}
