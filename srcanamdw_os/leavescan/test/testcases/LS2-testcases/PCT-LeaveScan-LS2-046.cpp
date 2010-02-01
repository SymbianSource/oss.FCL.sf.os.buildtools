//desc:test specialised template constructor of a Lclass for LS2
//option:
//date:2008-8-12 15:58:1
//author:pingorliu
//type: CT

class Ltemp
{
template<class T>
Ltemp(T x)
{

	fooL();

}
};

template<>
Ltemp::Ltemp<TInt>()
{//check:contain,leaver
	foo();
}
