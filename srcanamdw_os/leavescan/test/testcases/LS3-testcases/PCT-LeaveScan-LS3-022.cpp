//desc:test OR_LEAVE call in member template function of a class for LS3
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
	serv.Connect() OR_LEAVE;  //check:func,OR_LEAVE
}
};
