//desc:test LD leave function call in member template function of a class for LS1
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
template<class T>
void func()
{
	T a;
	a.b.c.fooLD(); //check:func,leave
}
};
