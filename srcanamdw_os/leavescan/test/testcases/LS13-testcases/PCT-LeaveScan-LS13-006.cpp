//desc:test LString is used as a return type of a overload function for LS13
//option:
//date:2008-8-21 14:10:2
//author:pingorliu
//type: CT

const TInt func(TInt x) 
{
}
const LString16 func() //check:func,return,LString
{
	foo();
}
