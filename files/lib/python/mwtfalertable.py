# -*- Mode: Python; tab-width: 2; indent-tabs-mode: nil -*-

import mwtfscribe

class Alertable(mwtfscribe.Scribe):
  def __init__(self, opts={}):
    super().__init__(opts)
