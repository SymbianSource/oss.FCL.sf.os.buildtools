//desc:test LData is used as a return type of a non-leaving friend function of a class for LS13
//option:
//date:2008-8-21 14:10:2
//author:pingorliu
//type: CT

class temp
{
	public:
friend LData func(); //check:func,return
};

LData func() //check:func
{
	foo();
}
