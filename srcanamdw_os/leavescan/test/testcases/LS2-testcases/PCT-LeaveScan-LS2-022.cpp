//desc:test leave function call when there is another TRAP of LS2
//option:
//date:2008-8-12 15:58:1
//author:pingorliu
//type: CT

void funcL()
{//check:-funcL,-leavers

	TRAP(fooL()); 
	if(i == 1)
	{
	//this is a function call//
	fxxLC(); 
	}
}
