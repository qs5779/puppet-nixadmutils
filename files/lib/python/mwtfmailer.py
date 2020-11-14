# -*- Mode: Python; tab-width: 2; indent-tabs-mode: nil -*-
import sys
from email.mime.text import MIMEText
from subprocess import Popen, PIPE
import mwtf

class Mailer(mwtf.Options):

  def __init__(self, opts={}):
    mopts = {
      'transport': 'sendmail'
    }
    mopts.update(opts)
    super().__init__(mopts)

  def send(self, args, body):
    if self.options['transport'] == 'sendmail':
      self.__send_sendmail(args, body)

  def __send_smtp(self, args, body):
    print("NOTICE: mailer __send_smtp not implemented yet!")
    print(args, body)

  def __send_sendmail(self, args, body):
    print("NOTICE: mailer __send_sendmail not implemented yet!")
    print(args, body)
    # msg = MIMEText(body)
    # msg["From"] = "me@example.com"
    # msg["To"] = "you@example.com"
    # msg["Subject"] = "This is the subject."
    # p = Popen(["/usr/sbin/sendmail", "-t", "-oi"], stdin=PIPE)

    # Both Python 2.X and 3.X
    # p.communicate(msg.as_bytes() if sys.version_info >= (3,0) else msg.as_string())
