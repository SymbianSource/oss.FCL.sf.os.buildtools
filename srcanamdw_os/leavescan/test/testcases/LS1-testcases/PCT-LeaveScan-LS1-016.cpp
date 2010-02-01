//desc:test memeber template leave function call of LS1
//option:
//date:2008-8-12 15:58:1
//author:pingorliu
//type: CT

void func()
{
	CL a;
	a.b.c.fooL<TInt,TEXT>(); //check:-func,-leave
}
