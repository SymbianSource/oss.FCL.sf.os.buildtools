//desc:test warning message:Uses->uses
//option:
//date:2008-12-22 14:58:10
//author:bolowy
//type: CT

void func()
{
	LCleanedup a; 
	CClass::NewLC();//check:uses
}

void func2()
{
	TRAP(CClass::NewLC());//check:uses
	LCleanedup a; 
}

void func3LC()
{
	LCleanedup a; 
	CClass::NewLC();//check:uses
}

void func4LC()
{
	LCleanedup a;
	CClass::NewLC();//check:uses
}



