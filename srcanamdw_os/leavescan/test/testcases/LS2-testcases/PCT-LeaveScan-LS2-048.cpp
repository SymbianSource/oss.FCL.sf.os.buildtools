//desc:test common function of a Lclass for LS2
//option:
//date:2008-8-12 15:58:1
//author:pingorliu
//type: CT

class Ltemp
{

void func()
{//check:-contain,-leaver
	foo();

}
void foo();
};


void Ltemp::foo()
{//check:-contain,-leaver
	foo();
}
