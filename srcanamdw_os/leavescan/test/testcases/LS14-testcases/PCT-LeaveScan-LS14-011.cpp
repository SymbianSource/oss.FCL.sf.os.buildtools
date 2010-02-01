//desc:test LDataXX is used as a parameter of a specialised function of a class for LS14
//option:
//date:2008-8-21 14:10:2
//author:pingorliu
//type: CT

class temp
{
	public:
template<class T>
const T func(const T y)const 
{
}
template<>
const void func<const LDataXX>(const LDataXX y)const //check:func,parameter
{
}
};
