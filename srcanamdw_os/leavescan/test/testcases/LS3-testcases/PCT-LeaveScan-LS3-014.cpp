//desc:test User::LeaveNoMemory LEAVE FUNCTION call in overload member function for LS3
//option:
//date:2008-8-12 15:58:1
//author:pingorliu
//type: CT


class temp
{
void func(TInt x)
{
	fxx();
}
void func()
{
	CL a;
	User::LeaveNoMemory(); //check:func,calls,Leave
}
};
