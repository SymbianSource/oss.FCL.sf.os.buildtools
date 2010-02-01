//desc:test LC LD LX of LS1
//option:
//date:2008-8-12 15:58:1
//author:pingorliu
//type: CT

void func()
{
/*fooLC();*/ //check:-func

/*
 *
 * fooLC();  //check:-func
 *
*/	

//this is a function call fooLD(); //check:-func

//"this is another function call fooLX();" //check:-func

string str = "calling fooLC()"; //check:-func
string str2 = "\"calling fooLD()\""; //check:-func
string str3 = "\"calling fooLX()"; //check:-func
string str4 = "'calling fooLC()'"; //check:-func
string str5 = "'calling fooLD()"; //check:-func
string str6 = " this is a function\
                fooLX()";  //check:-func

MARCOFOOLLLD(); //check:func

fooLDD(); //check:-func
}

