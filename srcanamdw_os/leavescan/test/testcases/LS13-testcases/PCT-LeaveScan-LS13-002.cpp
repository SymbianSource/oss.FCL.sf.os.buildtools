/*
* Copyright (c) 2009 Nokia Corporation and/or its subsidiary(-ies).
* All rights reserved.
* This component and the accompanying materials are made available
* under the terms of "Eclipse Public License v1.0"
* which accompanies this distribution, and is available
* at the URL "http://www.eclipse.org/legal/epl-v10.html".
*
* Initial Contributors:
* Nokia Corporation - initial contribution.
*
* Contributors:
*
* Description: 
*
*/
//desc:test LString is used as a return type of a non-leaving member function of a class for LS13
//option:
//date:2008-8-21 14:10:2
//author:pingorliu
//type: CT

class temp
{
	public:
LString16 func() //check:func,return,LString
{
	foo();
}
};
