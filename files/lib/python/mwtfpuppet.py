# frozen_string_literal: true

import os
import re
import sys
import errno
import configparser
from datetime import datetime
import mwtf
import mwtfalertable

class PuppetFlags(mwtfalertable.Alerter):
  def __init__(self, opts={}):
    super().__init__(opts)
    if self.istest():
      self.flag_dir = '/tmp/flags'
    else:
      self.flag_dir = '/root/flags'

  def flags(self):
    return ['debug', 'noipv6', 'nowarn', 'stopped']

  def flag_fpn(self, flag):
    return os.path.join(self.flag_dir, flag + '.puppet')

  def flag_exists(self, flag):
    return os.path.exists(self.flag_fpn(flag))

  def show_flags(self):
    self.__ensure_flag_directory()
    for flag in self.flags():
      # print(flag)
      print('wtfo_puppet_%s=%s' %(flag, self.flag_exists(flag)))
    if self.istest():
      print("\ntest mode flagdir: %s" % self.flag_dir)

  def isvalid(self, flag):
    try:
      _ignore = self.flags().index(flag)
      result = True
    except ValueError:
      self.warn('Invalid flag: ' + flag)
      self.errors += 1
      result = False
    return result

  def manage(self, flag, action):
    if self.isvalid(flag):
      self.__ensure_flag_directory()
      fpn = self.flag_fpn(flag)
      exists = self.flag_exists(flag)
      if action:
        if not exists:
          os.system('touch %s' % fpn)
      elif exists:
        os.unlink(fpn)

  def cli_run(self):
    if self.options['clear'] != None:
      for flag in self.options['clear']:
        self.manage(flag, False)
    if self.options['set'] != None:
      for flag in self.options['set']:
        self.manage(flag, True)
    self.show_flags()
    return self.errors

  def __ensure_flag_directory(self):
    if not self.istest():
      mwtf.requires_super_user
    mwtf.ensure_directory(self.flag_dir)

class PuppetConfig(PuppetFlags):
  def __init__(self, opts={}):
    super().__init__(opts)
    self.interval = None
    self.settings = None
    self.__init_pathnames()

  def setting(self, key, section = 'agent'):
    if self.settings == None:
      self.__load_config()
    if section in self.settings:
      return self.settings[section][key]
    self.warn('Section not found: %s' % section)
    self.errors += 1
    return ''

  def show_section(self, section = 'agent'):
    if self.settings == None:
      self.__load_config()
    if section in self.settings:
      print('[%s]' % section)
      for key in self.settings[section]:
        print('%s = %s' % (key, self.settings[section][key]))
    else:
      self.warn('Section not found: %s' % section)
      self.errors += 1
    return self.errors

  def show_setting(self, key, section = 'agent'):
    if self.settings == None:
      self.__load_config()
    if key == None:
      self.show_section(section)
    else:
      value = self.setting(key, section)
      print('[%s] %s = %s' % (section, key, value))
    return self.errors

  def show_config(self):
    if self.settings == None:
      self.__load_config()
    label = None
    for section in self.settings:
      for key in self.settings[section]:
        if section != label:
          if not label == None:
            print()
          label = section
          print('[%s]' % label)
        print('%s = %s' % (key, self.settings[section][key]))
    return self.errors

  def pathname(self, pathkey):
    try:
      _ignore = self.__pathkeys().index(pathkey)
      key = 'puppet.%s.file.status' % pathkey
      if self.pathnames[pathkey]['pn'] == None:
        args = {
          'key': key,
          'subject': self.pathnames[pathkey]['status'],
          'message': '%s. Please investigate.' % key
        }
        self.raise_alert(args)
      else:
        args = { 'key': key }
        self.clear(args)
      return self.pathnames[pathkey]['pn']
    except ValueError:
      self.warn('Invalid pathkey: ' + pathkey)
      self.errors += 1
      raise

  # protected

  def _run_interval(self):
    if self.interval is None:
      ri = int(self.setting('runinterval'))
      if ri:
        self.interval = int(ri)
      else:
        self.interval = 7200
    return self.interval

  def __pathkeys(self):
    return ['config', 'state', 'lastrun', 'bin']

  def __init_pathnames(self):
    self.pathnames = {}
    for path in self.__pathkeys():
      self.pathnames[path] = {}
      self.pathnames[path]['pn'] = None
      self.pathnames[path]['status'] = 'File not found.'
    self.__init_config()
    self.__init_last()
    self.__init_bin()

  def __init_file_pathname(self, choices, label, check = 'readable'):
    for pn in choices:
      if not os.path.exists(pn):
        continue

      good = 'good'
      status = good
      if check == 'executable':
        if not os.access(pn, os.X_OK):
          status = "Unsupported attribute %s for: %s" % (check, pn)
      elif check == 'readable':
        if not os.access(pn, os.R_OK):
          status = "Unsupported attribute %s for: %s" % (check, pn)
      else:
        status = "Unsupported attribute %s for: %s" % (check, pn)

      if status == good:
        self.pathnames[label]['pn'] = pn
      self.pathnames[label]['status'] = status
      break

  def __init_config(self):
    possibles = [
      '/etc/puppetlabs/puppet/puppet.conf',
      '/etc/puppet/puppet.conf'
    ]
    self.__init_file_pathname(possibles, 'config')

  def __init_state(self):
    possibles = [
      '/opt/puppetlabs/puppet/cache/state',
      '/var/cache/puppet/state', # debian 9 puppet
      '/var/lib/puppet/state' # fedora 30 puppet
    ]
    self.__init_file_pathname(possibles, 'state')

  def __init_bin(self):
    possibles = [
      '/opt/puppetlabs/bin/puppet',
      '/usr/bin/puppet'
    ]
    self.__init_file_pathname(possibles, 'bin', 'executable')

  def __init_last(self):
    self.__init_state()

    if self.pathnames['state']['pn'] == None:
      self.pathnames['lastrun']['status'] = self.pathnames['state']['status']
      return

    possibles = [os.path.join(self.pathnames['state']['pn'], 'last_run_summary.yaml')]
    self.__init_file_pathname(possibles, 'lastrun')

  def __load_config(self):
    if self.settings == None:
      if self.pathnames['config']['pn'] == None:
        raise FileNotFoundError(errno.ENOENT, "Puppet config file %s!!!" % self.pathnames['config']['status'])
      self.settings = configparser.ConfigParser()
      self.settings.read(self.pathnames['config']['pn'])


class PuppetCommon(PuppetConfig):
  def __init__(self, opts={}):
    super().__init__(opts)
    self.exit_code = 0

  def _is_run_okay(self, action):
    result = True
    if not self.options.get('force', False):
      if mwtf.uptime() < 300:
        self.exit_code = 11
        self.warn('%s action skipped due to insufficient uptime.' % action)
        result = False
      elif self.flag_exists('stopped'):
        self.exit_code = 13
        self.warn('%s action skipped due to stopped puppet flag.' % action)
        result = False
    return result

class PuppetStatus(PuppetCommon):
  def __init__(self, opts={}):
    super().__init__(opts)
    self.rc = {} # TODO: read config file

  def lock_pid(self, fpn):
    pid = False
    f = open(fpn, 'r')
    for line in f:
      try:
        pid = int(line.strip())
      except ValueError:
        pid = False
      break
    return pid

  def check(self):
    self.check_catalog_run_lock()
    self.check_last_run_yaml()

    if self.istest():
      print('Checked!')
    return self.exit_code

  def secs_since_last_run(self, summary, interval):
    if 'time' in summary and 'last_run' in summary['time']:
      lastrunsecs = summary['time']['last_run']
      self.trace('summary lastrunsecs: %d' % lastrunsecs, 2)
    else:
      lastrunsecs = mwtf.file_age(self.pathname('lastrun'))
    now = mwtf.secsepochsince()
    elapsed = now - lastrunsecs
    self.trace('now: %d lastrunsecs: %d' % (now, lastrunsecs), 2)
    if self.options.get('screen', sys.stdout.isatty()):
      lastrun = datetime.fromtimestamp(lastrunsecs)
      nextrun = datetime.fromtimestamp(now + (interval - elapsed))
      print('Puppet last run: %s ' % lastrun)
      print('Puppet next run: %s (estimated)' % nextrun)
      if self.isdebug():
        snow = datetime.fromtimestamp(now)
        print('now: %s' % snow)
        self.trace('elapsed: %d interval: %d' % (elapsed, interval))
    return elapsed

  def check_last_run_yaml(self):
    lastrunyaml = self.pathname('lastrun')
    self.trace('lastrunyaml: %s' % lastrunyaml)
    summary = mwtf.load_yaml(lastrunyaml)
    ri = self._run_interval()
    result = self.secs_since_last_run(summary, ri) > ri
    self.debug('check_last_run_yaml returning %s' % result)
    return result

  def check_catalog_run_lock(self):
    catlock_fn = os.path.join(self.pathname('state'), 'agent_catalog_run.lock')
    age = mwtf.file_age(catlock_fn)
    maxruntime = self.rc.get('maxpupppetrunage', 600) # defalt 10 minutes
    if age > maxruntime:
      pid = self.lock_pid(catlock_fn)
      if pid:
        msg = "%s\nage: %d, pid: %d" % (catlock_fn, age, pid)
        ec = os.system('kill -s 0 %d' % pid)
        if ec == 0:
          self.raise_alert({'key': 'puppet.hung.catalog.lock', 'message': msg})
        else:
          self.raise_alert({'key': 'puppet.stale.catalog.lock', 'message': msg})
      else:
        self.warn('Failed to extract pid from: %s' % catlock_fn)
    else:
      self.clear({'key': 'puppet.hung.catalog.lock'})
      self.clear({'key': 'puppet.stale.catalog.lock'})

class PuppetTrigger(PuppetStatus):

  def trigger(self):
    if self._is_run_okay('trigger'):
      if self.check_last_run_yaml():
        self.__run()
      # print(self.check_last_run_yaml())
      # print('exit_code: %d' % self.exit_code)
    return self.exit_code

  def __run_agent(self):
    if self.options['test']:
      self._debug('puppet run triggered, but skipped due to test flag')
      result = 0
    else:
      runner = '/opt/nixadmutils/sbin/runpup'
      if self.pathnames['bin']['status'] != 'good':
        raise self.pathnames['bin']['status']
      if not os.path.exists(runner):
        raise FileNotFoundError('File not found: %s' % runner)
      if not os.path.exists(runner):
        raise FileNotFoundError('File not found: %s' % runner)
      if not os.access(runner, os.X_OK):
        raise PermissionError('File not executable: %s' % runner)
      result = os.system(runner)
    return result

  def __run(self):
    result = self.__run_agent()
    if result == 0:
      self.info('Puppet run succeeded with no changes or failures.')
    elif result == 1:
      self.error("Puppet run failed, or wasn't attempted due to another run already in progress.")
    elif result == 2:
      self.info('Puppet run succeeded, and some resources were changed.')
    elif result == 4:
      self.warn('Puppet run succeeded, and some resources failed.')
    elif result == 6:
      self.warn('Puppet run succeeded, and included both changes and failures.')
    else:
      self.error('Puppet run exited with %d' % result)
    return result
