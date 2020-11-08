# -*- Mode: Python; tab-width: 2; indent-tabs-mode: nil -*-
import os
import re
import mwtf
import mwtfscribe
import mwtfmailer
from logging import (CRITICAL, ERROR, WARNING, INFO, DEBUG, NOTSET)
from filelock import Timeout, FileLock


class Alerts(mwtf.Options):
    def clear(self, args):
      return 0

    def lift(self, args):
      return 'Not implemented'

    def load(self):
      return 'Not implemented'

    def save(self):
      return 'Not implemented'

    def show(self):
      return 'Not implemented'

    def lockname(self):
      return 'Notimplemented'

class Alerter(mwtfscribe.Scribe):
  def __init__(self, opts={}):
    self.alerts = Alerts(opts)
    self.mailer = mwtfmailer.Mailer(opts)
    if not 'domain' in opts:
      dn = os.system('hostname -d')
      opts['domain'] = dn
    else:
      dn = opts['domain']

    maddr = 'root@%s' % dn

    aopts = {
      'caller': 'wtfalert',
      'level': WARNING,
      'to': maddr,
      'from': maddr,
      'throttle': 86400,
      'store': '/opt/nixadmutils/var',
      'smtphost': 'localhost',
      'screen': False,
      'test': False
    }
    aopts.update(opts)
    super().__init__(aopts)
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
    self.__alert_action(self, 'dump')

  # Emails message for specified alert
  def send_alert(self, args, body):
    self.mailer.send(args, body)

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
    self.warn( message)
    if re.match('^Alert throttled:', message) is None:
      self.sent += 1
    else:
      self.throttled += 1
  # rescue Error => e
  #   error e.backtrace if @debug
  #   error e.message

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
    self.__alert_masked(action, args)
    os.umask(saved_mask)
  # rescue StandardError => e
  #   error e.message
  #   File.umask(saved_mask) unless saved_mask.nil?
  # end

  def __alert_masked(self, action, args):
    lock = FileLock(self.alerts.lockname())
    with lock:
      self.alerts.load()
      self.__do_action(action, args)
      self.alerts.save()
    # raise "Failed to obtain lock #{lockname}" unless locked
  # rescue StandardError => e
  #   if @debug
  #     e.backtrace.each do |bt|
  #       debug bt
  #     end
  #   end
  #   error e.message
  # end
