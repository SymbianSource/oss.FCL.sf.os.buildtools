//desc:test member template LX function call of LS1
//option:
//date:2008-8-12 15:58:1
//author:pingorliu
//type: CT

void func()
{
	CL a;
	a.b.c.fooLX<TInt,TEXT>(   /*       \
	*/); //check:-func,-leave
}
