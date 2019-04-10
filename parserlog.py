#!/usr/bin/python3
import smtplib,ssl

nginxlog = "/var/log/nginx/access.log"

#Read Access Log

records={}
with open(nginxlog,"r") as fh:
    for line in fh:
        line = line.replace('\n','')
        linearray = line.split(' ')
        key = linearray[6] + '|' + linearray[8]
        if key in records:
            records[key] = records[key] + 1
        else:
            records[key] = 1

msg = ''
for k,v in records.items():
    msg = msg + str(v) + '|' + k + '\n'

print(msg)

port = 587  # For starttls
smtp_server = "smtp.gmail.com"
sender_email = "jbalbuen22@gmail.com"
receiver_email = "jbalbuen22@gmail.com"
password = "XXXXXXXX" 
message = msg 


context = ssl.create_default_context()
with smtplib.SMTP(smtp_server, port) as server:
    server.ehlo()  # Can be omitted
    server.starttls(context=context)
    server.ehlo()  # Can be omitted
    server.login(sender_email, password)
    server.sendmail(sender_email, receiver_email, message)


