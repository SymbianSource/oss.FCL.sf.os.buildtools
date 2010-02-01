//desc: test LCleanedup is used to declare a common data member of a abstract struct
//option:
//date:2008-8-20 13:51:31
//author:pingorliu
//type: CT

class temp
{
	virtual void func() = 0;
	private:
                LCleanedupPtr<TInt> member; //check:LCleanedup,data,member
};
