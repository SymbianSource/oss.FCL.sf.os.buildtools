//desc:test leave function call in member function definition out of a class for LS2
//option:
//date:2008-8-12 15:58:1
//author:pingorliu
//type: CT
class CC
{
void funcL();
};

void CC::funcL()
{//check:-funcL,-leavers

	CL::fooL();
}

