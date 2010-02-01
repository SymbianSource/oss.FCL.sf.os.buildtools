//desc:test leave function call in operator overload function for LS1
//option:
//date:2008-8-12 15:58:1
//author:pingorliu
//type: CT


int operator+(TInt x,TInt y)
{
	fxx();
}
void operator+(TInt x, TEXT y)
{
	CL a;
	a.b.c.fooLD(); //check:leave
}
