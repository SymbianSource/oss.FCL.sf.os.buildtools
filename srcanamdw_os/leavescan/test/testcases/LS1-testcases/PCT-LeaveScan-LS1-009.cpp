//desc:test leave function call when there is a class definiton of LS1
//option:
//date:2008-8-12 15:58:1
//author:pingorliu
//type: CT

class CC
{
};

void func()
{
	fooL(); //check:func,leave
}
