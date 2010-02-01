//desc: test LCleanedup class not used with Classic cleanup in template function for LS15
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
CFoo* foo1 = CFoo::NewLC(); //check:-with,-LCleaned
}

};
