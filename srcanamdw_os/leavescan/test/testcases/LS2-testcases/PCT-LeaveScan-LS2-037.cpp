//desc:test leave function call in a member template function of a class for LS2
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
template<class T>
void funcL()
{//check:-funcL,-leavers

	
	FooL();
}
};
