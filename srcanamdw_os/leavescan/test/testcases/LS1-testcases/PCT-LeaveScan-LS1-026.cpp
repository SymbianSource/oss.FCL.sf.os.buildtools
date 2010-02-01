//desc:test leave function call in member operator overload function for LS1
//option:
//date:2008-8-12 15:58:1
//author:pingorliu
//type: CT


class temp
{
int operator+(TInt x)
{
	fxx();
}
void operator+(TEXT y)
{
	CL a;
	a.b.c.fooLX(); //check:leave
}
};
