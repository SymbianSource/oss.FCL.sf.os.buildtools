//desc:test LData is used as a parameter of a specialised function of a class for LS14
//option:
//date:2008-8-21 14:10:2
//author:pingorliu
//type: CT

class temp
{
	public:
template<class T>
const T func(const T x)const 
{
}
template<>
const void func<LString16>(const LData x)const //check:func,parameter
{
}
};
