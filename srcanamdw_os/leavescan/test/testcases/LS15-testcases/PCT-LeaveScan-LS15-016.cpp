//desc: test LCleanedup class not used with Classic cleanup PushL in operator function for LS15
//option:
//date:2008-8-21 15:19:15
//author:pingorliu
//type: CT

class temp
{
	public:
TInt operator+(TInt x)
{
CFoo* foo2 = CFoo::NewL(); 
CleanupStack::PushL(foo2); //check:-with,-LCleaned

}
};
