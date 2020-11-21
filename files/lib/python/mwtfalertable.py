# -*- Mode: Python; tab-width: 2; indent-tabs-mode: nil -*-
import os
import sys
import re
import yaml
import mwtf
import mwtfscribe
import mwtfmailer
from datetime import datetime
from logging import (CRITICAL, ERROR, WARNING, INFO, DEBUG, NOTSET)
from filelock import Timeout, FileLock

CREATED = ':created'
RESCUED = ':rescued'
COUNT = ':count'
LAST = ':last'
THROTTLED = ':throttled'

class Alerts(mwtf.Options):
  def __init__(self, opts={}):
    super().__init__(opts)
    self.mailer = mwtfmailer.Mailer(opts)
    self.data_pathname = None
    self.myhost = None
    self.dirty = False
    if self.options.get('store') is None:
      self.options['store'] = '/opt/nixadmutils/var'
    if self.options.get('throttle') is None:
      self.options['throttle'] = 86400
    for sd in [self.options['store'], os.getenv('HOME'), '/tmp']:
      spn = os.path.join(sd, 'alerts.yaml')
      try:
        self.__check_store(sd, spn)
        self.data_pathname = spn
        self.lockname = '%s.lock' % spn
        break
      except:
        _ignore = True

  def save(self):
    if self.dirty:
      if self.data_pathname is None:
        raise ValueError('Failed to find a valid data pathname!!!')
      saved_mask = os.umask(2)
      try:
        with open(self.data_pathname, 'w') as outfile:
          outfile.write("---\n")
          yaml.dump(self.data, outfile)
          outfile.write("...\n")
      except:
        os.umask(saved_mask)
        raise

  def load(self):
    if self.data_pathname is None:
      raise ValueError('Failed to find a valid data pathname!!!')
    self.dirty = False
    if os.path.exists(self.data_pathname):
      self.__load_data(self.data_pathname)
    else:
      self.data = {}
      self.data[CREATED] = str(datetime.now())
      self.dirty = True
    if self.dirty:
      self.save()

  def clear(self, args):
    self.trace('Alerts::clear called')
    key = args['key']
    last, _throttled = self.__clear_key(key)
    result = 0
    if last < 0:
      self._debug('key not found: %s ' % key)
    elif last > 0:
      body = "Alert cleared (throttled #{throttled} times) for key: #{key}"
      args['subject'] = '%s alert cleared' % key
      self.__compose(args, body)
      self._verbose('Alert cleared for key: %s' % key)
      result = 1
    else:
      self._debug('nothing to clear for key: %s' % key)
    return result

  def show(self):
    if self.isdebug():
      print(self.data)
    yaml.dump(self.data, sys.stdout)

  def send(self, args, body):
    self.mailer.send(args, body)

  def lift(self, args, body = 'no message specified'):
    self.trace('Alerts::lift called')
    self.__verify_key(args['key'])
    key = args['key']
    throttle = args.get('throttle', self.options['throttle'])
    if not self.__throttled(key, throttle):
      self.__compose(args, body)
      result = 'Alert sent for: %s' % key
    else:
      throttled = self.data[key][THROTTLED]
      s = self.__compose_subject(args)
      result = "Alert throttled: %s (%d times)" % (s, throttled)
    return result

  # private methods
  def __compose_subject(self, args):
    hn = mwtf.hostname()
    if 'subject' in args:
      if re.search(hn, args['subject']):
        subject = args['subject']
      else:
        subject = '%s on %s' %(args[:subject], hn)
    else:
      subject = "%s alert on %s" % (args['key'], hn)
    return subject

  def __compose(self, args, body):
    opts = {
      'to': self.options['to'],
      'from': self.options['from']
    }
    opts.update(args)
    self.__compose_message(opts, body)

  def __compose_message(self, args, default=None):
    args['subject'] = self.__compose_subject(args)
    msg = args.get('message', '')
    if 'filename' in args:
      f = open(args['filename'],'r')
      msg += f.read()
    if not msg:
      if default:
        msg = default
      else:
        msg = 'No message specified'
    self.mailer.send(args, msg)

  def __throttled(self, key, throttle):
    now = mwtf.secsepochsince()
    if (now - self.data[key][LAST]) > throttle:
      self.data[key][THROTTLED] = 0
      self.data[key][LAST] = now
      result = False
    else:
      self.data[key][THROTTLED] += 1
      result = True
    self.dirty = True
    return result

  def __clear_key(self, key):
    last = -1
    throttled = -1
    if key in self.data:
      throttled = 0
      last = 0
      if LAST in self.data[key]:
        last = self.data[key][LAST]
        if last != 0:
          throttled = self.data[key][THROTTLED]
          self.data[key][LAST] = 0
          self.data[key][THROTTLED] = 0
          self.dirty = True
    return [last, throttled]

  def __verify_key(self, key):
    if key in self.data:
      for kk in [COUNT, LAST, THROTTLED]:
        if kk in self.data[key]:
          if not type(self.data[key][kk]) == int:
            if type(self.data[key][kk]) == float:
              self.data[key][kk] = int(self.data[key][kk])
            else:
              self.data[key][kk] = 0
            print('WARNING: reintialized alert key: %s %s to integer value' % (key, kk))
          self.dirty = True
        else:
          self.data[key][kk] = 0
          self.dirty = True
    else:
      self.data[key] = {}
      self.data[key][COUNT] = 0
      self.data[key][LAST] = 0
      self.data[key][THROTTLED] = 0
      self.dirty = True

  def __load_data(self, fpn):
    self.dirty = False
    self.data = mwtf.load_yaml(fpn)
    if self.data is None:
      self.data = {}
      self.data[RESCUED] = str(datetime.now())
      self.dirty = True

  def __check_store(self, parent, fpn):
    if not os.path.isdir(parent):
      raise NotADirectoryError('Pathname "%s" is not a directory.' % dir)
    if os.path.exists(fpn):
      if not os.access(fpn, os.R_OK):
        raise PermissionError('File "%s" is not readable.' % fpn)
      if not os.access(fpn, os.W_OK):
        raise PermissionError('File "%s" is not writable.' % fpn)
    elif not os.access(parent, os.W_OK):
        raise PermissionError('Directory "%s" is not writable.' % parent)

class Alerter(mwtfscribe.Scribe):
  def __init__(self, opts={}):
    dn = mwtf.domainname()
    maddr = 'root@%s' % dn

    aopts = {
      'caller': 'wtfalert',
      'level': WARNING,
      'to': maddr,
      'from': maddr,
    }
    aopts.update(opts)
    sopts = {
      'caller': 'wtfalert',
      'level': WARNING,
    }
    sopts.update(opts)
    super().__init__(sopts)
    self.alerts = Alerts(aopts)
    self.cleared = self.throttled = self.sent = 0

  # Clears an alerter where:
  #  args {
  #     key      => 'unique alert key', # required
  #     subject  => 'subject',          # optional
  #     message  => 'message',          # optional
  #     filename => 'pathname',         # optional read file into message
  #  }
  #
  def clear(self, args):
    self.__alert_action('clear', args)

  # Raises an alerter where:
  #  args {
  #     key      => 'unique alert key', # required
  #     subject  => 'subject',          # optional
  #     message  => 'message',          # optional
  #     filename => 'pathname',         # optional read file into message
  #  }
  #
  def raise_alert(self, args):
    self.__alert_action('raise', args)

  # Prints the loaded alert data:
  def dump(self):
    self.__alert_action('dump')

  # Emails message for specified alert
  def send_alert(self, args, body):
    self.alerts.send(args, body)

  def status(self):
    # simplifies my rspec tests
    self.raised = self.sent + self.throttled
    format = 'raised: %d cleared: %d sent: %d throttled: %d errors: %d'
    result = format % (self.raised, self.cleared, self.sent, self.throttled, self.errors)
    self.debug(result)
    return result

  def __clear_action(self, args):
    self.debug('clear_action called')
    if args == None:
      raise ValueError('args paramater required for clear_action')
    if 'key' not in args:
      raise ValueError('Failed to clear alert. Missing key argument.')
    self.cleared += self.alerts.clear(args)

  def __raise_action(self, args):
    self.debug('raise_action called')
    if args == None:
      raise ValueError('args paramater required for clear_action')
    if 'key' not in args:
      raise ValueError('Failed to clear alert. Missing key argument.')
    message = self.alerts.lift(args)
    self.warn(message)
    if re.match('^Alert throttled:', message) is None:
      self.sent += 1
    else:
      self.throttled += 1

  def __do_action(self, action, args):
    if re.search('^(dump|show)$', action):
      self.alerts.show()
    elif action == 'raise':
      self.__raise_action(args)
    elif action == 'clear':
      self.__clear_action(args)
    else:
      message = 'Unknown action: %s' % action
      self.fatal(action)
      raise ValueError(message)

  def __alert_action(self, action, args = None):
    self.debug('alert_action called for %s' % action)
    saved_mask = os.umask(2)
    try:
      self.__alert_masked(action, args)
      os.umask(saved_mask)
    except:
      os.umask(saved_mask)
      raise

  def __alert_masked(self, action, args):
    lock = FileLock(self.alerts.lockname, timeout=3)
    with lock:
      self.alerts.load()
      self.__do_action(action, args)
      self.alerts.save()

