//desc:test leave function call in member function definition out of a class for LS1
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
	CL::fooL(); //check:func,leave
}

