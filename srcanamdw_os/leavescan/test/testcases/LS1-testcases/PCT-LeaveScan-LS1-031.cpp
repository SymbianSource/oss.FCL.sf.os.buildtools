//desc:test difference of class and function LS1
//option:
//date:2008-8-12 15:58:1
//author:pingorliu
//type: CT


class CC
{
	void func(); //check:-leave
};
struct CL
{
	void fooL(); //check:-leave
};

struct
{
	void fooL(); //check:-leave
}cc;

class CX
{
	public:
		TInt x;
		class CXX
		{
			void fooL(); //check:-leave
		};
};

