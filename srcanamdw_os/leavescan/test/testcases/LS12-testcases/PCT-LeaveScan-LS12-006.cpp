//desc:test LCleanup class used in operator function for LS12
//option:
//date:2008-8-12 15:58:1
//author:pingorliu
//type: CT

class temp
{
TInt operator+(TInt y)
{

	TRAP(LCleanedupHandle<RBaz> baz);//check:-improper
	TRAPD(result,LString8 s(KMaxString));//check:-improper
	

	

}

};
