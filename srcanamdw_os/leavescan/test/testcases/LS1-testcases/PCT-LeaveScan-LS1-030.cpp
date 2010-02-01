//desc:test common function call of LS1
//option:
//date:2008-8-12 15:58:1
//author:pingorliu
//type: CT

void func()
{

fooLLc(); //check:-func,-leave

foo(); //check:-func,-leave

TInt y = foo(); //check:-func,-leave

}
