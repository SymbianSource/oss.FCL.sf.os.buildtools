//desc:test a common member leave function definiton that no leavers of a template class for LS2
//option:
//date:2008-8-12 15:58:1
//author:pingorliu
//type: CT

template<class T>
class temp
{
void funcL()
{//check:funcL,leavers
   
	T x = 1;
	foo();

}
};

