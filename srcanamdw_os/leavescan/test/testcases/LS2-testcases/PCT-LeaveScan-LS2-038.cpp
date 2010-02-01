//desc:test LD leave function call in member template function of a class for LS2
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

	T a;
	a.b.c.fooLD();
}
};
