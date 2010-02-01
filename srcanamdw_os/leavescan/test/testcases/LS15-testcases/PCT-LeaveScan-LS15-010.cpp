//desc: test LCleanedup class used with Classic cleanup PushL in template function for LS15
//option:
//date:2008-8-21 15:19:15
//author:pingorliu
//type: CT

class temp
{
	public:

template<class T>
void funcL()
{

}
template<>
void funcL<TInt>()
{
LCleanedupHandle<RBar> bar;
CFoo* foo1 = CFoo::NewLC(); //check:with,LCleaned
}

};
