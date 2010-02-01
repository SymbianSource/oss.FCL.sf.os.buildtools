//desc:test comment and string and marco of LS1
//option:
//date:2008-8-12 15:58:1
//author:pingorliu
//type: CT

void func()
{
/*fooL();*/ //check:-func

/*
 *
 * fooL();  //check:-func
 *
*/	

//this is a function call fooL(); //check:-func

//"this is another function call fooL();" //check:-func

string str = "calling fooL()"; //check:-func
string str2 = "\"calling fooL()\""; //check:-func
string str3 = "\"calling fooL()"; //check:-func
string str4 = "'calling fooL()'"; //check:-func
string str5 = "'calling fooL()"; //check:-func
string str6 = " this is a function\
                fooL()";  //check:-func

MARCOFOOL(); //check:func,macro

int b = 1;
fx(/*fooL()*/ b); //check:-func
fx(/*                                        fooL()//        */ b); //check:-func
}

