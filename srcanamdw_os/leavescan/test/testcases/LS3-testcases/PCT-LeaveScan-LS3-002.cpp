//desc:test TRAP and TRAPD of LS3
//option:
//date:2008-8-12 15:58:1
//author:pingorliu
//type: CT

void func()
{

	
	TRAP(new(ELeave)CL()); //check:-func,-calls
        TRAP(User::Leave()); //check:-func,-calls
	TRAP(User::LeaveIfError()         ); //check:-func,-calls

	TRAPD(result,   User::Leave(        )     ); //check:-func,-calls

}
