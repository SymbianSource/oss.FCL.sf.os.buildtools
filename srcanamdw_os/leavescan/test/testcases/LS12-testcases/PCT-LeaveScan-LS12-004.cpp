//desc:test LCleanup class used in leaving specialised template function for LS12
//option:
//date:2008-8-12 15:58:1
//author:pingorliu
//type: CT

template<class T>
void funcL()
{

	LCleanedupHandle<T> baz;//check:-improper
	LString8 s(KMaxString);//check:-improper
	LData buf(KMaxBuf)   ;//check:-improper

        /*this is a function call */ LData buf(KMaxBuf) /*hello*/    ;//check:-improper
	


}
template<>
void funcL<TInt>()
{
LCleanedupHandle<T> baz;//check:-improper

}
