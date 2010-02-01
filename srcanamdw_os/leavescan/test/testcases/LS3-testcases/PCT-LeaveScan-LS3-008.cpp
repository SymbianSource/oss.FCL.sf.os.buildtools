//desc:test new(ELeave) call as a argument of a member template function call for LS3
//option:
//date:2008-8-12 15:58:1
//author:pingorliu
//type: CT

void func()
{
	CL a;
	a.b.c.foo<TInt,TEXT>(new(ELeave)CL()                       ); //check:func,ELeave
}
