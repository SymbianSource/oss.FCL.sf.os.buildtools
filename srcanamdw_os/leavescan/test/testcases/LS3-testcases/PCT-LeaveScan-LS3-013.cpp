//desc:test User::LeaveIfError function call in overload function for LS3
//option:
//date:2008-8-12 15:58:1
//author:pingorliu
//type: CT


void func(TInt x)
{
	fxx();
}
void func()
{
	CL a;
	User::LeaveIfError(); //check:func,calls
}
