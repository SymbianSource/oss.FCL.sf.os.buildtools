//desc: test LCleanedup class used with Classic cleanup PushL in type cast function for LS15
//option:
//date:2008-8-21 15:19:15
//author:pingorliu
//type: CT

class temp
{
	public:
operator TInt()
{
LCleanedupHandle<RBar> bar;
CFoo* foo2 = CFoo::NewL(); 
CleanupStack::PushL(foo2); //check:with,LCleaned
}
};
