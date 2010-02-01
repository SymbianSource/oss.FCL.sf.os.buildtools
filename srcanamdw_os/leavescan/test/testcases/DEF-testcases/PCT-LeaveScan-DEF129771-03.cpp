//desc:test User::LeaveIfError function call in a leave member template function of a class for LS3
//option:
//date:2008-10-31 15:58:1
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
{
	
	User::LeaveIfError(); //check:-func,-calls,-Leave
}
};