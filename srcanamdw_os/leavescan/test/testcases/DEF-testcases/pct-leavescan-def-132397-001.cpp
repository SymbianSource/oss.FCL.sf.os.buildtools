//desc:check preprocessor:NONSHARABLE_CLASS
//option:
//date:2008-12-22 14:58:10
//author:bolowy
//type: CT

NONSHARABLE_CLASS (c)
{
	LCleanedupPtr<CBaz> iBaz; //check:class
};

