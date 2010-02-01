//desc:test specialised template operator of a Lclass for LS2
//option:
//date:2008-8-12 15:58:1
//author:pingorliu
//type: CT

class Ltemp
{
template<class T>
TInt operator-(T x)
{

	fooL();

}
};

template<>
TInt Ltemp::operator-<TInt>()
{//check:contain,leaver
	foo();
}
