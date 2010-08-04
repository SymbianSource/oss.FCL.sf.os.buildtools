// Copyright (c) 2007-2009 Nokia Corporation and/or its subsidiary(-ies).
// All rights reserved.
// This component and the accompanying materials are made available
// under the terms of "Eclipse Public License v1.0"
// which accompanies this distribution, and is available
// at the URL "http://www.eclipse.org/legal/epl-v10.html".
//
// Initial Contributors:
// Nokia Corporation - initial contribution.
//
// Contributors:
// Mike Kinghan, mikek@symbian.org, for Symbian Foundation, 2010 
//
// Description:
// FileDump Operations of elf2e32 tool to dump E32Image and generate ASM File.
// @internalComponent
// @released
// 
//

#include "pl_common.h"
#include "filedump.h"
#include "e32imagefile.h"
#include "h_utl.h"
#include "deffile.h"
#include "errorhandler.h"
#include <cstdio>
#include <cassert>

/**
Constructor for class FileDump
@param aParameterListInterface - Instance of class ParameterListInterface
@internalComponent
@released
*/
FileDump::FileDump(ParameterListInterface* aParameterListInterface) : UseCaseBase(aParameterListInterface)
{
}

/**
Destructor for class FileDump
@internalComponent
@released
*/
FileDump::~FileDump()
{
}

/**
Execute Function for the File Dump. It dumps E32 image or generate ASM file based on the
file dump options
@return 0 on success, otherwise throw error 
@internalComponent
@released
*/
int FileDump::Execute()
{
	if(iParameterListInterface->FileDumpOption() && iParameterListInterface->E32OutOption() && iParameterListInterface->DefFileInOption()) //DumpAsm
	{
		if(!(iParameterListInterface->DumpOptions() & EDumpAsm))
			throw InvalidArgumentError(INVALIDARGUMENTERROR,(!iParameterListInterface->FileDumpSubOptions()?"":iParameterListInterface->FileDumpSubOptions()) ,"--dump");
		if(iParameterListInterface->DumpOptions() & 31)
			throw InvalidArgumentError(INVALIDARGUMENTERROR,(!iParameterListInterface->FileDumpSubOptions()?"":iParameterListInterface->FileDumpSubOptions()),"--dump");
		if(!iParameterListInterface->E32ImageOutput())
			throw ParameterParserError(NOREQUIREDOPTIONERROR,"--output");
		if(!iParameterListInterface->DefInput())
			throw ParameterParserError(NOREQUIREDOPTIONERROR,"--definput");

		GenerateAsmFile();
	}
	else
	{
		if(!iParameterListInterface->E32Input())
			throw ParameterParserError(NOREQUIREDOPTIONERROR,"--e32input");
		if(iParameterListInterface->DumpOptions() & EDumpAsm )
			throw InvalidArgumentError(INVALIDARGUMENTERROR,iParameterListInterface->FileDumpSubOptions() ,"--dump");
		DumpE32Image();
	}
	return 0;
}

/**
Function to generate ASM File.
@param afileName - ASM File name
@return 0 on success, otherwise throw error 
@internalComponent
@released
*/
int FileDump::GenerateAsmFile() //DumpAsm
{
	EAsmDialect asmDialect = iParameterListInterface->AsmDialect();
	switch(asmDialect)
	{
	case EGas:
		return GenerateGasAsmFile();
	case EArmas:
		return GenerateArmasAsmFile();
	default:
		assert(false);
	}
	return 0;
}

/**
Function to generate an RVCT armas ASM File.
@param afileName - ASM File name
@return 0 on success, otherwise throw error 
@internalComponent
@released
*/
int FileDump::GenerateArmasAsmFile()
{
	DefFile *iDefFile = new DefFile();
	SymbolList *aSymList;
	aSymList = iDefFile->ReadDefFile(iParameterListInterface->DefInput());
	char const *afileName = iParameterListInterface->E32ImageOutput(); 

	FILE *fptr;

	if((fptr=fopen(afileName,"w"))==NULL)
	{
		throw FileError(FILEOPENERROR,(char*)afileName);
	}
	else
	{
		SymbolList::iterator aItr = aSymList->begin();
		SymbolList::iterator last = aSymList->end();
		Symbol *aSym;

		while( aItr != last)
		{
			aSym = *aItr;

			if(aSym->Absent())
			{
				aItr++;
				continue;
			}

			fputs("\tIMPORT ",fptr);
			fputs(aSym->SymbolName(),fptr);
			//Set the visibility of the symbols as default."DYNAMIC" option is
			//added to remove STV_HIDDEN visibility warnings generated by every 
			//export during kernel build 
			fputs(" [DYNAMIC]", fptr);
			fputs("\n",fptr);
			aItr++;
		}

        // Create a directive section that instructs the linker to make all listed
        // symbols visible.

        fputs("\n AREA |.directive|, READONLY, NOALLOC\n\n",fptr);

        fputs("\tDCB \"#<SYMEDIT>#\\n\"\n", fptr);

		aItr = aSymList->begin();
		while (aItr != last)
		{
			aSym = *aItr;

			if ( aSym->Absent() )
			{
				aItr++;
				continue;
			}

            // Example:
            //  DCB "EXPORT __ARM_ll_mlass\n"
			fputs("\tDCB \"EXPORT ",fptr);
			fputs(aSym->SymbolName(),fptr);
			fputs("\\n\"\n", fptr);

			aItr++;
		}

		fputs("\n END\n",fptr);
		fclose(fptr);
	}
	return 0;
}

/**
Function to generate a GNU as ASM File.
@param afileName - ASM File name
@return 0 on success, otherwise throw error 
@internalComponent
@released
*/
int FileDump::GenerateGasAsmFile()
{
	DefFile *iDefFile = new DefFile();
	SymbolList *aSymList;
	aSymList = iDefFile->ReadDefFile(iParameterListInterface->DefInput());
	char const *afileName = iParameterListInterface->E32ImageOutput(); 

	FILE *fptr;

	if((fptr=fopen(afileName,"w"))==NULL)
	{
		throw FileError(FILEOPENERROR,(char*)afileName);
	}
	else
	{
		SymbolList::iterator aItr = aSymList->begin();
		SymbolList::iterator last = aSymList->end();
		Symbol *aSym;

		while( aItr != last)
		{
			aSym = *aItr;

			if(aSym->Absent())
			{
				aItr++;
				continue;
			}
			fputs("\t.global ",fptr);
			fputs(aSym->SymbolName(),fptr);
			fputs("\n",fptr);
			aItr++;
		}

		fclose(fptr);
	}
	return 0;
}


/**
Function to Dump E32 Image.
@param afileName - E32 Image File name
@return 1 on success, otherwise throw error 
@internalComponent
@released
*/
int FileDump::DumpE32Image()
{
	char const *afileName = iParameterListInterface->E32Input(); 
	E32ImageFile *aE32Imagefile=new E32ImageFile();
	TInt result = aE32Imagefile->Open(afileName);
	
	if (result > 0)
		return 1;
	else if (result == KErrCorrupt || result == KErrNotSupported)
	{
		throw InvalidE32ImageError(INVALIDE32IMAGEERROR, (char *)afileName);
	}
	else if (result != 0)
	{
		throw FileError(FILEREADERROR, (char *)afileName);
	}

	int dumpOptions=iParameterListInterface->DumpOptions();
	
	aE32Imagefile->Dump((TText*)afileName, dumpOptions);
	delete aE32Imagefile;
	return KErrNone;
}

