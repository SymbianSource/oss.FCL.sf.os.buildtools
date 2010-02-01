//desc:test OR_LEAVE call of LS3
//option:
//date:2008-8-12 15:58:1
//author:pingorliu
//type: CT

void func()
{
	serv.Connect() OR_LEAVE;  //check:func,OR_LEAVE
}
