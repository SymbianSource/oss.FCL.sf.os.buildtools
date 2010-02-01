@echo off

set JAVA_HOME=c:\Apps\jre1.5.0_13
set PATH=c:\Apps\jre1.5.0_13\bin;%PATH%

echo java -Xmx1100M -Xrs -jar %EPOCROOT%cdb\cdb\cdb.jar --epocroot %EPOCROOT% %*
java -Xmx1100M -Xrs -jar %EPOCROOT%cdb\cdb\cdb.jar --epocroot %EPOCROOT% %*

