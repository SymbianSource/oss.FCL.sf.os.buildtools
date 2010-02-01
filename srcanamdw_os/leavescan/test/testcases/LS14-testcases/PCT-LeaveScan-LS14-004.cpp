//desc:test LString is used as a parameter of a template function of a class for LS14
//option:
//date:2008-8-21 14:10:2
//author:pingorliu
//type: CT

class temp
{
	public:
template<class T>
void func(const LString16 x)const //check:func,parameter
{
}
};
