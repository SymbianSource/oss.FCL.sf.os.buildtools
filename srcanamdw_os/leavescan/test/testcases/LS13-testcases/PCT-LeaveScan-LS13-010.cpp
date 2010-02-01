//desc:test LData is used as a return type of a specialised function of a class for LS13
//option:
//date:2008-8-21 14:10:2
//author:pingorliu
//type: CT

class temp
{
	public:
template<class T>
const T func()const 
{
}
template<>
const LData func<LString16>()const //check:func,return
{
	foo();
}
};
