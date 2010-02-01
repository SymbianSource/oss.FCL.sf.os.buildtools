//desc:test a overload member leave function definiton that no leavers for LS2
//option:
//date:2008-8-12 15:58:1
//author:pingorliu
//type: CT

class temp
{
void funcL(TInt x)
{
	fooL();
}
void funcL()
{//check:funcL,leavers
   
	TInt x = 1;
	foo();

}
};

