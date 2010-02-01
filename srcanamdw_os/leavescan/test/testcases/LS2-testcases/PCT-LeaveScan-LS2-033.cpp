//desc:test leave function call in a member function definition of a template class for LS2
//option:
//date:2008-8-12 15:58:1
//author:pingorliu
//type: CT
template<class T>
class CC
{
	void funcL();
};

template<class T>
void CC::funcL()
{//check:-funcL,-leavers

	CL::fooL();
}

