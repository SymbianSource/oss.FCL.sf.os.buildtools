//desc:test new(ELeave) call in member function definition out of a class for LS3
//option:
//date:2008-8-12 15:58:1
//author:pingorliu
//type: CT
class CC
{
void func();
};

void CC::func()
{
	new(ELeave)CL(); //check:func,ELeave
}

