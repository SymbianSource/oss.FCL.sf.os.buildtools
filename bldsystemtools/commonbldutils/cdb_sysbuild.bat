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
@echo off

set JAVA_HOME=c:\Apps\jre1.5.0_13
set PATH=c:\Apps\jre1.5.0_13\bin;%PATH%

echo java -Xmx1100M -Xrs -jar %EPOCROOT%cdb\cdb\cdb.jar --epocroot %EPOCROOT% %*
java -Xmx1100M -Xrs -jar %EPOCROOT%cdb\cdb\cdb.jar --epocroot %EPOCROOT% %*

