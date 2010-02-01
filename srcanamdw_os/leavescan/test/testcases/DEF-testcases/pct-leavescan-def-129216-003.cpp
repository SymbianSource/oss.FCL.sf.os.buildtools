//desc:test warning message:Call->call
//option:
//date:2008-12-22 14:58:10
//author:bolowy
//type: CT

void func()
{
	new(ELeave)B(); //check:calls
}

