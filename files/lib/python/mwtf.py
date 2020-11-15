# -*- Mode: Python; tab-width: 2; indent-tabs-mode: nil -*-

import os

def uptime(elevate = True):
  try:
    with open('/proc/uptime', 'r') as f:
      uptime_seconds = float(f.readline().split()[0])
      return int(uptime_seconds)
  except:
    if elevate:
      raise
  return 0

def secsepochsince():
  return int(os.popen("date '+%s'").read().rstrip())

def file_age(pathname):
  if os.path.exists(pathname):
    result = secsepochsince() - int(os.path.getmtime(pathname))
  else:
    result = 0
  return result

def ensure_directory(dir, perm=0o755):
  if os.path.isdir(dir):
    return True
  if os.path.exists(dir):
    raise NotADirectoryError('Pathname "%s" is not a directory.' % dir)
  os.makedirs(dir,mode=perm)

def requires_super_user(prefix='Specified action'):
  if os.geteuid() != 0:
    raise PermissionError('%s requires super user priviledges.' % prefix)

class Options:
  def __init__(self, opts={}):
    self.options = {
      'debug': 0,
      'verbose': 0,
      'test': False
    }
    self.errors = 0
    self.options.update(opts)
    if self.options['test']:
      print('created instance of class %s' % self.__class__.__name__)

  def isdebug(self):
    return self.options['debug']>0

  def isverbose(self):
    return self.options['verbose']>0

  def istest(self):
    return self.options['test']

  def trace(self, message, level = 1):
    if self.options['test'] or self.options['debug'] >= level:
      print(message)

  def _debug(self, message):
    self.trace(message)

  def _verbose(self, message, level = 1):
    if self.options['test'] or self.options['verbose'] >= level:
      print(message)
