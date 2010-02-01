//desc:test leave function call when there is another TRAP of LS1
//option:
//date:2008-8-12 15:58:1
//author:pingorliu
//type: CT

void func()
{
	TRAP(fooL()); //check:-func,-leave
	if(i == 1)
	{
	//this is a function call//
	fxxLC(); //check:func,leave
	}
}
