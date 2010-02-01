//desc:test TRAP and TRAPD of LS1
//option:
//date:2008-8-12 15:58:1
//author:pingorliu
//type: CT

void func()
{
	TRAP(fooL()); //check:-func,-leave
	TRAP(fooLC()); //check:-func,-leave
	TRAP(                                    fooL()   ); //check:-func,-leave

        TRAP(/*this is a function call */ fooL() /*hello*/    ); //check:-func,-leave
	

	TRAPD(result,fooL()  ); //check:-func,-leave

}
