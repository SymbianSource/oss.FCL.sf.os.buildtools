//desc:test new(ELeave) function call in type cast function of a class for LS3
//option:
//date:2008-8-12 15:58:1
//author:pingorliu
//type: CT


class temp
{
operator int()
{
	CL a;
	new(ELeave)(); //check:operator,ELeave
}
};
