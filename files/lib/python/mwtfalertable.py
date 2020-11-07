# -*- Mode: Python; tab-width: 2; indent-tabs-mode: nil -*-

import mwtfscribe

class Alerter(mwtfscribe.Scribe):
  def __init__(self, opts={}):
    defaults = {
      'debug': 0,
      'verbose': 0,
      'test': False
    }
    self.errors = 0
    self.options.update(opts)
    super().__init__(opts)
