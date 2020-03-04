#!/usr/bin/python
import smtplib
from email.mime.text import  MIMEText
from email.header import Header

sender = 'yaoyuanchun@wind-mobi.com'
receiver = ['yaoyuanchun@wind-mobi.com']
mail_user = 'yaoyuanchun@wind-mobi.com'
mail_passwd = 'yyc041600'
mail_host = 'smtp.wind-mobi.com'

message = MIMEText('version build failed !!!!!','plain','utf-8')
message['from'] = Header('<reporter> yaoyuanchun@wind-mobi.com','utf-8')
message['to'] = Header('yaoyuanchun@wind-mobi.com','utf-8')

subject = 'DailyBuild report'
message['subject'] = Header(subject,'utf-8')

try:
	smtpObj = smtplib.SMTP()
        smtpObj.connect(mail_host,25)
        smtpObj.login(mail_user,mail_passwd)
	smtpObj.sendmail(sender,receiver,message.as_string())
	print "successful"
except smtplib.SMTPException:
	print "failed"
