//desc: test LCleanedup class used with Classic cleanup PushL in member function that defined out of class for LS15
//option:
//date:2008-8-21 15:19:15
//author:pingorliu
//type: CT

template<class T>
class temp
{
	public:
void funcL();
};
template<class T>
void temp::funcL<T>()
{
LCleanedupHandle<RBar> bar;
CFoo* foo2 = CFoo::NewL(); 
CleanupStack::PushL(foo2); //check:with,LCleaned


}
	
