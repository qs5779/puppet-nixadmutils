# -*- Mode: Python; tab-width: 2; indent-tabs-mode: nil -*-

import mwtf
import logging
from systemd.journal import JournalHandler

class Scribe(mwtf.Options):
  def __init__(self, opts={}):
    super().__init__(opts)

    self.log = logging.getLogger('demo')

    if ('level' not in self.options) or (self.options['level'] == None):
      self.options['level'] = logging.INFO

    if ('level' not in self.options) and (self.options['level'] != None):
      logging.basicConfig(filename=self.options['logfile'],format='%(asctime)s - %(message)s')
    else:
      self.log.addHandler(JournalHandler(SYSLOG_IDENTIFIER=self.options['caller']))

    self.log.setLevel(self.options['level'])

  def debug(self, message, *args, **kwargs):
    self.log.debug(message, *args, **kwargs)

  def info(self, message, *args, **kwargs):
    self.log.info(message, *args, **kwargs)

  def warn(self, message, *args, **kwargs):
    self.log.warning(message, *args, **kwargs)

  def error(self, message, *args, **kwargs):
    self.log.error(message, *args, **kwargs)
    self.errors += 1

  def fatal(self, message, *args, **kwargs):
    self.log.critical(message, *args, **kwargs)
    self.errors += 1

  def unknown(self, message, *args, **kwargs):
    self.log.log(self.options['level'], message, *args, **kwargs)
