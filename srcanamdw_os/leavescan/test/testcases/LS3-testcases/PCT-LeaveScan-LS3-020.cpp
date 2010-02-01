//desc:test new(ELeave) function call in override member function for LS3
//option:
//date:2008-8-12 15:58:1
//author:pingorliu
//type: CT

class base
{
	void func(TInt x)
	{
	}
	void func()
	{
	}

};
class temp:public base
{
void func(TInt x)
{
	fxx();
}
void func()
{
	CL a;
	new(ELeave)(); //check:func,ELeave
}
};
