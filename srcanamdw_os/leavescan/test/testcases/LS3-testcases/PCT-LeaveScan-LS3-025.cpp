//desc:test OR_LEAVE call in member specialised template function of a class with TRAP for LS3
//option:
//date:2008-8-12 15:58:1
//author:pingorliu
//type: CT


class temp
{
template<class T>
void func(TInt x)
{
	fxx();
}
template<>
void func<TInt>(TInt x)
{
	T a;
	TRAP(serv.Connect() OR_LEAVE);  //check:-func,-calls,-Leave
}
};
