//desc: test other type is used to declare a friend class of a common class
//option:
//date:2008-8-20 13:51:31
//author:pingorliu
//type: CT

class temp
{
	private:
                friend LCleanedupPtr; //check:LCleanedup,data,member
};
