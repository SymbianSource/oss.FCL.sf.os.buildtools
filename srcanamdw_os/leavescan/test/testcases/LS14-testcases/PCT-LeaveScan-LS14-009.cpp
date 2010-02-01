//desc:test LData is used as a parameter of a non-leaving friend function of a class for LS14
//option:
//date:2008-8-21 14:10:2
//author:pingorliu
//type: CT

class temp
{
	public:
friend  void func(LData x); //check:func,parameter
};

void func(LData x) //check:func,parameter
{
}
