//desc:test TRAP and TRAPD of LS2
//option:
//date:2008-8-12 15:58:1
//author:pingorliu
//type: CT

void funcL()
{//check:funcL,leavers

	TRAP(fooL());
	TRAP(fooLC());
	TRAP(                                    fooL()   );

        TRAP(/*this is a function call */ fooL() /*hello*/    );
	

	TRAPD(result,fooL()  );

}
