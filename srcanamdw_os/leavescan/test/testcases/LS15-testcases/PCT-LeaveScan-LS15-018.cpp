//desc: test LCleanedup class not used with Classic cleanup PushL in type cast function for LS15
//option:
//date:2008-8-21 15:19:15
//author:pingorliu
//type: CT

class temp
{
	public:
operator TInt()
{
CFoo* foo1 = CFoo::NewL(); 
CleanupStack::PushL(foo1); //check:-with,-LCleaned
CFoo* foo2 = CFoo::NewL(); 
CleanupStack::PushL(foo2); //check:-with,-LCleaned

}
};
