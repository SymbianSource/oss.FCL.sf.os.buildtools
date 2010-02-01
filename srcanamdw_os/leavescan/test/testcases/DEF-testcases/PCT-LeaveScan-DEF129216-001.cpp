//desc:test hang-->"classA"
//option:
//date:2008-10-121 15:58:10
//author:bolowy
//type: CT

void func()
{
	T a;
	a.fooL(classA); //check:func,leave
}
};
