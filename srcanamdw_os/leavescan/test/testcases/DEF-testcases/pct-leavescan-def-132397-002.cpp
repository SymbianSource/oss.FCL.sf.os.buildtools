//desc:check preprocessor:NONSHARABLE_STRUCT
//option:
//date:2008-12-22 14:58:10
//author:bolowy
//type: CT

NONSHARABLE_STRUCT (c)
{
	LCleanedupPtr<CBaz> iBaz; //check:class
};

