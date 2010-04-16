@rem
@rem Copyright (c) 2009 Nokia Corporation and/or its subsidiary(-ies).
@rem All rights reserved.
@rem This component and the accompanying materials are made available
@rem under the terms of "Eclipse Public License v1.0"
@rem which accompanies this distribution, and is available
@rem at the URL "http://www.eclipse.org/legal/epl-v10.html".
@rem
@rem Initial Contributors:
@rem Nokia Corporation - initial contribution.
@rem
@rem Contributors:
@rem
@rem Description: 
@rem

@ECHO OFF
@REM This batch file removes MAS (ActiveSync) from the CBR archive(s) indicated by RelTools.ini

@REM SETLOCAL ensures that when we exit this batchfile, Current Directory and EPOCROOT will be restored to "as found" state.
SETLOCAL

@REM %BuildDir%\bin\%Platform% is the same as %OutputDir%. But we must not have a drive letter at the start of EPOCROOT.

CD /d %BuildDir%\bin\%Platform%\generic
@ECHO CD = %BuildDir%\bin\%Platform%\generic

SET EPOCROOT=\bin\%Platform%\generic\
@ECHO Calling RemoveRel -v mas
Call RemoveRel -v mas
@ECHO Calling RemoveRel -v techview_mas
Call RemoveRel -v techview_mas

CD /d %BuildDir%\bin\%Platform%\techview
@ECHO CD = %BuildDir%\bin\%Platform%\techview

SET EPOCROOT=\bin\%Platform%\techview\
@ECHO Calling RemoveRel -v mas
Call RemoveRel -v mas
@ECHO Calling RemoveRel -v techview_mas
Call RemoveRel -v techview_mas

