//desc:test LCleanup class used in leaving member function for LS12
//option:
//date:2008-8-12 15:58:1
//author:pingorliu
//type: CT

class temp
{
void funcL()
{

	LCleanedupHandle<RBaz> baz;//check:-improper
	LString8 s(KMaxString);//check:-improper
	LData buf(KMaxBuf)   ;//check:-improper

        /*this is a function call */ LData buf(KMaxBuf) /*hello*/    ;//check:-improper
	

	

}
template<class T>
void fooL();

};
template<class T>
void temp::fooL()
{
LString8 s(KMaxString);//check:-improper
}
