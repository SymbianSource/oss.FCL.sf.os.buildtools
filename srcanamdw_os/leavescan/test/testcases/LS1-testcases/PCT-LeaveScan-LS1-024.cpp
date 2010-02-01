//desc:test leave function call in overload member function for LS1
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
	a.b.c.fooLC(); //check:func,leave
}
};
