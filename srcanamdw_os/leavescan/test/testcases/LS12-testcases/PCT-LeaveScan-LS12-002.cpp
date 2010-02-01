//desc:test LCleanup class used in leaving function for LS12
//option:
//date:2008-8-12 15:58:1
//author:pingorliu
//type: CT

void funcL()
{

	LCleanedupHandle<RBaz> baz;//check:-improper
	LString8 s(KMaxString);//check:-improper
	LData buf(KMaxBuf)   ;//check:-improper

        /*this is a function call */ LData buf(KMaxBuf) /*hello*/    ;//check:-improper
	

	

}
