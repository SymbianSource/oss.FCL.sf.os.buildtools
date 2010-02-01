//desc:test a member leave function call of LS1
//option:
//date:2008-8-12 15:58:1
//author:pingorliu
//type: CT

class CL;
class CL:public CC
{
};
void func()
{
	CL a;
	a.b.c.fooL(); //check:func,leave
}
