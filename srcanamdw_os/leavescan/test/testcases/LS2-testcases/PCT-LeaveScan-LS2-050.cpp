//desc:test operator with calling leaving function of a Lclass for LS2
//option:
//date:2008-8-12 15:58:1
//author:pingorliu
//type: CT

class Ltemp
{
TInt operator++()
{//check:-contain,-leaver
fooL();

}
TInt operator+(TInt x);
};

TInt Ltemp::operator+(TInt x)
{//check:-contain,-leaver
	fooL();
}
