//desc:test OR_LEAVE call in leaving function of LS3
//option:
//date:2008-8-12 15:58:1
//author:pingorliu
//type: CT

void funcL()
{
	serv.Connect() OR_LEAVE;  //check:-func,-calls
}
