# frozen_string_literal: true

import os
import errno
import configparser
import mwtf
import mwtfalertable


class PuppetFlags(mwtfalertable.Alertable):
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
      alertkey = 'puppet.%s.file.status' % pathkey
      if self.pathnames[pathkey]['pn'] == None:
        args = {
          :key => key,
          :subject => @pathnames[label][:status],
          :message => "#{key}. Please investigate."
        }
        self.send_alert args
      else
        args = { :key => key }
        clear_alert args
      end
      @pathnames[label][:fn]
    except ValueError:
      self.warn('Invalid pathkey: ' + pathkey)
      self.errors += 1
      raise

  def __pathkeys(self):
    return ['config', 'state', 'lastrun', 'bin']

  def __init_pathnames(self):
    self.pathnames = {}
    for path in self.__keys():
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
    return 12

class PuppetStatus(PuppetCommon):

  def check(self):
    self.check_catalog_run_lock()
    self.check_last_run_yaml()

    if self.istest():
      print('Checked!')
    return self.exit_code

  def check_catalog_run_lock(self)
    catlock_fn = File.join(pathname(state), 'agent_catalog_run.lock')

    age = Wtf.file_age catlock_fn
    maxruntime = @rc.key?('maxpupppetrunage') ? @rc['maxpupppetrunage'] : 600 # 10 minutes

    if age > maxruntime
      pid = lock_pid(catlock_fn)

      if pid
        msg = "#{catlock_fn}\nage: #{age}, pid: #{pid}"
        _stdout_str, _error_str, status = Open3.capture3('kill', '-s 0', pid.to_s)
        if status.success?
          send_alert(:key => 'puppet.hung.catalog.lock', :message => msg)
        else
          send_alert(:key => 'puppet.stale.catalog.lock', :message => msg)
        end
      else
        log_warn "Failed to extract pid from: #{catlock_fn}"
      end
    else
      clear_alert :key => 'puppet.hung.catalog.lock'
      clear_alert :key => 'puppet.stale.catalog.lock'
    end

class PuppetTrigger(PuppetCommon):

  def trigger(self):
    return 1

  def __run_agent(self):
    return 1

  def __run(self):
    result = self.__run_agent()
    if result == 0:
      self.log_info('Puppet run succeeded with no changes or failures.')
    elif result == 1:
      self.log_error("Puppet run failed, or wasn't attempted due to another run already in progress.")
    elif result == 2:
      self.log_info('Puppet run succeeded, and some resources were changed.')
    elif result == 4:
      self.log_warn('Puppet run succeeded, and some resources failed.')
    elif result == 6:
      self.log_warn('Puppet run succeeded, and included both changes and failures.')
    else:
      self.log_error('Puppet run exited with %d' % result)
    return result