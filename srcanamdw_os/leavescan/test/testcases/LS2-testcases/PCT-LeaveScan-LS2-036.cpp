//desc:test leave function call in overload member function for LS2
//option:
//date:2008-8-12 15:58:1
//author:pingorliu
//type: CT


class temp
{
void funcL(TInt x)
{
	fxx();
}
void funcL()
{//check:-funcL,-leavers

	CL a;
	fleaveL();
}
};
