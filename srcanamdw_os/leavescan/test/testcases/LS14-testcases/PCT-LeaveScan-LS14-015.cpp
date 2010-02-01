//desc:test LString is used as a parameter of a specialised leaving function of a class for LS14
//option:
//date:2008-8-21 14:10:2
//author:pingorliu
//type: CT

class temp
{
	public:
template<class T>
const T func(const T x )const 
{
}
template<>
const LString16 funcLC<LString16>(const LString16 x)const //check:-func,-parameter
{
}
};
