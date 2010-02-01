//desc:check preprocessor:xxNONSHARABLE_CLASSyy
//option:
//date:2008-12-22 14:58:10
//author:bolowy
//type: CT

foo(){;}NONSHARABLE_CLASS(c)
{
	LCleanedupPtr<CBaz> iBaz; //check:class
};

