//desc: test other type is used to declare a common data member of a common class
//option:
//date:2008-8-20 13:51:31
//author:pingorliu
//type: CT

class temp
{
	private:
                LManagedPtr<CBaz> member; //check:-LCleanedup,-data,-member
};
