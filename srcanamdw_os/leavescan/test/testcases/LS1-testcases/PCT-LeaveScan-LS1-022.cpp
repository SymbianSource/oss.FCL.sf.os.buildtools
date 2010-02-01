//desc:test leave function call in a member template function definition of a template class for LS1
//option:
//date:2008-8-12 15:58:1
//author:pingorliu
//type: CT
template<class T>
class CC
{
	void func();
};

template<class T>
void CC::func()
{
        fLeaveL(); //check:func,leave
}

