//desc: test other type is used to declare a data member of a common class of a namespace
//option:
//date:2008-8-20 13:51:31
//author:pingorliu
//type: CT

namespace mysp
{
class temp
{
	private:
                LCleanedupPtr pp; //check:LCleanedup,data,member
};
}
