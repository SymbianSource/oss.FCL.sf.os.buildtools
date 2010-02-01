//desc:test template leave function call in overload function for LS1
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
	a.b.c.fooL<TInt>(); //check:-func,-leave
}
