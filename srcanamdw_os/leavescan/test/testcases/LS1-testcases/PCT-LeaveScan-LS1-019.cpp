//desc:test calling a leave function in member function for LS1
//option:
//date:2008-8-12 15:58:1
//author:pingorliu
//type: CT
class CC
{
void func()
{
	CL::fooL(); //check:func,leave
}
};
