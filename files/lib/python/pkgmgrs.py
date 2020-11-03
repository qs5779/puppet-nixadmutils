# -*- Mode: Python; tab-width: 2; indent-tabs-mode: nil -*-

import distro
import subprocess

class Error(Exception):
  """Base class for exceptions in this module."""
  pass

class UsageError(Error):
  """Exception raised for errors with supplied arguments or parameters

  Attributes:
      message -- explanation of the error
  """

  def __init__(self, message):
      self.message = message

class PackageHandler:
  def __init__(self, opts={}):
    self.options = {
      'debug': 0,
      'verbose': 0,
      'test': False
    }
    self.options.update(opts)

  def validate_arg_count(self, action, args, expected):
    if len(args) != expected:
      raise UsageError('action %s requires %d arguments' % (action, expected))

  def file_action(self, args):
    print("class %s doesn't handle a file action!" % type(self).__name__)
    return 1

  def action(self, action, args):
    if (self.options['debug']>0) or (self.options['verbose']>0):
      print('action: ' + action)
      print('args: ', args)
    if action == 'file':
      self.validate_arg_count(action, args, 1)
      result = self.file_action(args)
    if (action == 'find') or (action == 'search'):
      self.validate_arg_count(action, args, 1)
      result = self.find_action(args)
    else:
      raise ValueError(action + ' is not a valid action!!!')
    return result

  def execute(self, cmd):
    try:
      subprocess.check_call(cmd)
      result = 0
    except subprocess.CalledProcessError as cpex:
      if (self.options['debug']>0) or (self.options['verbose']>0):
        print(cpex)
      result = cpex.returncode
    except Exception as ex:
      print(ex)
      result = 1
    return result

class PacmanHandler(PackageHandler):
  def __init__(self, opts={}):
    super().__init__(opts)
    if self.options['test']:
      print('created instance of PacmanHandler')

  def file_action(self, args):
    return self.execute(['pacman', '-Qo', args[0]])

  def find_action(self, args):
    # TODO: option to refresh local caches
    return self.execute(['pacman', '-Ss', args[0]])

class AptHandler(PackageHandler):
  def __init__(self, opts={}):
    super().__init__(opts)
    if self.options['test']:
      print('created instance of AptHandler')

  def file_action(self, args):
    if self.options['names-only']:
      return self.execute(['apt', 'search', '--names-only', args[0]])
    else:
      return self.execute(['apt', 'search', '--names-only', args[0]])

class YumHandler(PackageHandler):
  def __init__(self, opts={}):
    super().__init__(opts)
    self.pkgcmd = 'yum'
    if self.options['test']:
      print('created instance of YumHandler')

  def file_action(self, args):
    return self.execute(['rpm', '-Qf', args[0]])

  def find_action(self, args):
    # TODO: option to refresh local caches
    return self.execute([self.pkgcmd, 'search', args[0]])

class DnfHandler(YumHandler):
  def __init__(self, opts={}):
    super().__init__(opts)
    self.pkgcmd = 'dnf'
    if self.options['test']:
      print('created instance of DnfHandler')


