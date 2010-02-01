//desc:test constructor with calling leaving function of a Lclass for LS2
//option:
//date:2008-8-12 15:58:1
//author:pingorliu
//type: CT

class Ltemp
{
Ltemp()
{//check:-contain,-leaver
fooL();

}
Ltemp(TInt x);
};

Ltemp::Ltemp(TInt x)
{//check:-contain,-leaver
	fooL();
}
