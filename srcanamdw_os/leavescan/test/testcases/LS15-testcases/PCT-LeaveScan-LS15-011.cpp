//desc: test LCleanedup class used with Classic cleanup in template function for LS15
//option:
//date:2008-8-21 15:19:15
//author:pingorliu
//type: CT

class temp
{
	public:

template<class T>
void func()
{

}
template<>
void func<TInt>()
{
LCleanedupXX<RBar> bar;
CFoo* foo1 = CFoo::NewLC(); //check:with,LCleaned
}

};
