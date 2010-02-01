//desc:test User::LeaveIfError function call in a member template function of a class for LS3
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
	
	User::LeaveIfError(); //check:func,calls,Leave
}
};
