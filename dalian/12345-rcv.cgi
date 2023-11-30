#!/usr/bin/python3
# coding:utf-8

import art
import base64
import cgi
import cgitb; cgitb.enable()
import json
import re
import requests
import datetime

import my

MAIL_API = <MAIL_API>

# http://tonop.cocolog-nifty.com/blog/2020/11/post-c6c35e.html
form = cgi.FieldStorage()

foo = form.getfirst("foo", "")
bar = form.getfirst("bar", "")
htm = form.getfirst("htm", "")
htm2 = str(base64.b64decode(htm), 'utf-8')
r = json.dumps([{'key':'foo','value':foo},  \
                {'key':'bar','value':bar},  \
                {'key':'htm','value':htm2}],\
                sort_keys=True, indent=4, ensure_ascii=False)

# to analyze target page in html
with open("./data/tgt.html", 'w', encoding="utf-8") as page:
  page.write(htm2)

# we have new data
if '---' not in htm2:
  # for debug
  t_delta = datetime.timedelta(hours=8)
  CST = datetime.timezone(t_delta, 'CST')
  now = datetime.datetime.now(CST)
  msg = now.strftime('%H:%M') + '\n有3条新增投诉'

  with open("./data/aaa.txt", "w") as myfile:
    myfile.write(msg)

  my.tts(msg)

  # mail inform
  requests.post(MAIL_API, json={"content": htm2}, timeout=(3.0, 30.5))

if 'callback' in form:
  callback = form.getfirst('callback', "callback")
  callback = re.sub(r'[^a-zA-Z_0-9\.]', '', callback)
  print ("Content-type: application/javascript; charset=utf-8\n\n")
  print ('%s(%s)' % (callback, r))
else:
  print ("Content-type: application/json; charset=utf-8\n\n")
  print (r)

