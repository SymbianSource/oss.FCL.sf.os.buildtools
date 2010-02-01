//desc:test LString is used as a return type of a non-leaving static function of a class for LS13
//option:
//date:2008-8-21 14:10:2
//author:pingorliu
//type: CT

class temp
{
	public:
static const LString16 func() //check:func,return,LString
{
	foo();
}
};
