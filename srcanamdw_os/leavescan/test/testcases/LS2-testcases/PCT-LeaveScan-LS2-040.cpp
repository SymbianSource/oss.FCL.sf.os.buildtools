//desc:test leave function call in override member function for LS2
//option:
//date:2008-8-12 15:58:1
//author:pingorliu
//type: CT

class base
{
	void funcL(TInt x)
	{
	}
	void funcL()
	{
	}

};
class temp:public base
{
void funcL(TInt x)
{
	fxx();
}
void funcL()
{//check:-funcL,-leavers

	CL a;
	a.b.c.fooL();
}
};
