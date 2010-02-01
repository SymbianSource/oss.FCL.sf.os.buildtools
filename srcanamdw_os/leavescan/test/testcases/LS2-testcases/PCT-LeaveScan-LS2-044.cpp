//desc:test operator function defined out of class of a Lclass for LS2
//option:
//date:2008-8-12 15:58:1
//author:pingorliu
//type: CT

class Ltemp
{
TInt operator+(TInt);
};

TInt Ltemp::operator+(TInt)
{//check:contain,leaver
	foo();

}

