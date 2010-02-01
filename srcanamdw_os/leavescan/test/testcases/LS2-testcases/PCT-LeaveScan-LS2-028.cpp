//desc:test memeber template leave function call of LS2
//option:
//date:2008-8-12 15:58:1
//author:pingorliu
//type: CT

void funcL()
{//check:+funcL,+leavers

	CL a;
	a.b.c.fooL<TInt,TEXT>();
}
