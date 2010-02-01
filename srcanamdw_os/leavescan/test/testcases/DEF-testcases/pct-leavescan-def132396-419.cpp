//desc: test class name identify with base-class-spec
//option:
//date:2009-1-12 11:0:58
//author:bolowyou
//type: CT
template<typename t, class tt>
class NS1  ::  MS2 :: myclass : protected NS1::NS2::myclass
{ 
	LCleanedup mem; //check:myclass
};
