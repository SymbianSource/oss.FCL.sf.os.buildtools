//desc:test TRAP and TRAPD of LS12
//option:
//date:2008-8-12 15:58:1
//author:pingorliu
//type: CT

void func()
{

	TRAP(LCleanedupHandle<RBaz> baz);//check:-improper
	TRAP(LString8 s(KMaxString));//check:-improper
	TRAP(                                    LData buf(KMaxBuf)   );//check:-improper

        TRAP(/*this is a function call */ LData buf(KMaxBuf) /*hello*/    );//check:-improper
	

	TRAPD(result,LCleanedupHandle<RBaz> baz2  );//check:-improper

}
