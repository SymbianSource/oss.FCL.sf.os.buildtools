# Copyright (c) 2003-2009 Nokia Corporation and/or its subsidiary(-ies).
# All rights reserved.
# This component and the accompanying materials are made available
# under the terms of the License "Eclipse Public License v1.0"
# which accompanies this distribution, and is available
# at the URL "http://www.eclipse.org/legal/epl-v10.html".
#
# Initial Contributors:
# Nokia Corporation - initial contribution.
#
# Contributors:
#
# Description:
# Script to send xml data to diamonds
# 
#
command_help = """
Send XML data from file to Diamonds. v.1.23
Use:
    send_xml_to_diamonds.py options
    
    Mandatory options:
    -s    Server address
    -u    Url
    -f    path of XML file
    
    Optional options:
    -m    Send only mail, without POST connection. Recommend only,
          when direct POST connection is not available.
    -o    mail server. Not needed inside Nokia intranet.
    -h    help
    
    Examples:
    Sending only by mail, without POST. (not recommended)
        send_xml_to_diamonds.py -s diamonds.nmp.nokia.com -u /diamonds/builds/ -f c:\\build.xml -m buildtoolsautomation@nokia.com
    
    Sending a new build to release instance of Diamonds
        send_xml_to_diamonds.py -s diamonds.nmp.nokia.com -u /diamonds/builds/ -f c:\\build.xml
    
    Updating test results to existing build
        send_xml_to_diamonds.py -s diamonds.nmp.nokia.com -u /diamonds/builds/123/ -f c:\\test.xml
    
    Sending data for Relative Change in SW Asset metrics
        send_xml_to_diamonds.py -s diamonds.nmp.nokia.com -u /diamonds/metrics/ -f c:\\relative.xml
    
    Sending data for Function Coverage
        send_xml_to_diamonds.py -s diamonds.nmp.nokia.com -u /diamonds/tests/coverage/ -f c:\\coverage.xml
    
    Note: If you want to send XML to development version of Diamonds in testing purposes, use
    address: trdeli02.nmp.nokia.com:9001 in the server address:
        send_xml_to_diamonds.py -s trdeli02.nmp.nokia.com:9001 -u /diamonds/builds/ -f c:\\build.xml
"""

from httplib import *
import os, sys, time, re


def send_email(subject, body, sender, receivers, encoding, mail_server):
    """
    Create an email message as MIMEText instance.
    """
    from email.Header import Header
    from email.MIMEText import MIMEText
    from email.Utils import parseaddr, formataddr
    import smtplib
    
    msg = MIMEText(body, "plain", encoding)
    msg["To"] = Header(u", ".join(receivers), encoding)
    msg["Subject"] = Header(subject, encoding)
    
    smtp = smtplib.SMTP() 
    smtp.connect(mail_server)
    smtp.sendmail(sender, receivers, msg.as_string())
    smtp.close()

def get_username():
    platform = sys.platform
    if platform == "win32":
        return os.getenv("USERNAME")
    else:
        return os.getlogin()

def get_mail_subject(sender, server, url):
    return "[DIAMONDS_DATA] %s>>>%s>>>%s" % (sender, server, url)

def get_response_message(response):
    return "Response status:%s \
    \nResponse reason:%s\n" \
           % (response.status, response.reason)

def get_process_time(total_time):
    if total_time<=60:
        return  "%s seconds" % round(total_time, 1)
    else:
        return "%s minutes and %s seconds" % (int(total_time/60), round((total_time%60), 1))

def main():
    start_time          = time.time()
    server_valid        = False
    url_valid           = False
    sfile_valid         = False
    mail_address        = None
    mail_server_address = "smtp.nokia.com"
    _                   = sys.argv.pop(0)
    
    while sys.argv:
        parameter = sys.argv.pop(0)
        if re.search('^-', parameter):
            if parameter == '-s':
                server       = sys.argv.pop(0)
                server_valid = True
            elif parameter == '-u':
                url          = sys.argv.pop(0)
                url_valid    = True
            elif parameter == '-f':
                source_file  = sys.argv.pop(0)
                sfile_valid  = True
                try:
                    xml = open(source_file).read()
                except:
                    sys.exit("Can not open the file %s" % source_file)
            elif parameter == '-m':
                mail_address = sys.argv.pop(0)
            elif parameter == '-o':
                mail_server_address = sys.argv.pop(0)
            elif parameter == '-h':
                sys.exit("HELP:\n %s" % (command_help))
            else:
                sys.exit("Incorrect parameter! %s" % (parameter) + command_help )
        else:
            sys.exit("Incorrect parameter! %s" % (parameter) + command_help)
    if not server_valid or not url_valid or not sfile_valid:
        sys.exit("Too few parameters: Use -h for help")
    
    diamonds_mail_box      = "diamonds@diamonds.nmp.nokia.com"
    import_failed_message  = "XML was not sent successfully to Diamonds via REST interface!\n"
    import_succeed_message = "XML was sent successfully to Diamonds via REST interface.\n"
    mail_sent_message      = "XML was sent to Diamonds by mail. Scheduled script will try to import it to Diamonds. If you can not see data soon in Diamonds, please contact to Diamonds developers.\n"
    
    if not mail_address:
        connection = HTTPConnection(server)
        
        try:
            connection.request("POST", url, xml)
        except:
            print "Can not connect to the server %s\n" % server
            sender = get_username()
            #send_email(get_mail_subject(sender, server, url), xml, sender, [diamonds_mail_box], "latin-1", mail_server_address)
            sys.exit(mail_sent_message)
        
        response = connection.getresponse()
        
        # More info about httplib
        # http://docs.python.org/lib/module-httplib.html
        if response.status == 200:
            print import_succeed_message
            print get_response_message(response)
            print "Server response:%s\n" % response.read()
        else:
            print import_failed_message
            print get_response_message(response)
            sender = get_username()
            #send_email(get_mail_subject(sender, server, url), xml, sender, [diamonds_mail_box], "latin-1", mail_server_address)
            print mail_sent_message
        
        connection.close()
           
    else:
        print 'Sending only mail'
        sender = get_username()
        #send_email(get_mail_subject(sender, server, url), xml, sender, [mail_address], "latin-1", mail_server_address)
    
    print "------------------------"
    print "Processed in %s" % get_process_time(time.time()-start_time)
    print "------------------------"

if __name__ == "__main__":
    main()
