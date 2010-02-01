//desc:test warning message:Returns->returns
////option:
//date:2008-12-22 14:58:10
//author:bolowy
//type: CT

class a
{
int i;
LData func(int a)//check:return
{
	foo(); 
}
void func2(LData a)//check:uses
{
	foo();
}
LString func3(int a)//check:return
{
	foo(); 
}
void func4(LString a)//check:uses
{
	foo();
}

};

LData func5(int a)//check:return
{
	foo(); 
}
void func6(LData a)//check:uses
{
	foo();
}
LString func7(int a)//check:return
{
	foo(); 
}
void func8(LString a)//check:uses
{
	foo();
}

