//desc:test User::Leave function call in member operator overload function for LS3
//option:
//date:2008-8-12 15:58:1
//author:pingorliu
//type: CT


class temp
{
int operator+(TInt x)
{
	fxx();
}
void operator+(TEXT y)
{
	CL a;
	User::Leave(); //check:calls,Leave
}
};
