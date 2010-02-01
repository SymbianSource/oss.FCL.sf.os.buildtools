//desc: test LCleanedup class used in member function that defined out of classfor LS16
//option:
//date:2008-8-21 15:19:15
//author:pingorliu
//type: CT

class temp
{
	public:
void funcLC();
};

void temp::funcLC()
{
LCleanedupHandle<RBar> bar;//check:suffixed,LCleanedup

}
