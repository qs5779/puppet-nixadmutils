#!/usr/bin/env python3
# -*- Mode: Python; tab-width: 2; indent-tabs-mode: nil -*-

import os
import sys
import json
import feedparser
from optparse import OptionParser

def main():
  usage = "usage: %prog [options]"
  parser = OptionParser(usage)
  parser.add_option("-d", "--debug", action="store_true", dest="debug", default=0, help='specify debug mode')
  parser.add_option("-V", "--version", action="store_true", dest="version", default=False, help='show version and exit')

  (opts, args) = parser.parse_args()

  options = vars(opts)

  if options['version']:
    basenm = os.path.basename(sys.argv[0])
    print('%s Version: 1.0.0' % basenm)
    exit(0)

  try:
    NewsFeed = feedparser.parse('https://www.quotedb.com/quote/quote.php?action=random_quote_rss')
    entry = NewsFeed.entries[0]
    if options['debug']:
      print(json.dumps(entry, indent=2))
    else:
      print('%s - %s' % (entry['summary'], entry['title']))
    failure = False
  except:
    failure = True

  if failure:
    quote = '"The phoenix must burn to emerge."'
    author = 'Janet Fitch'
    print('%s - %s' % (quote, author))

if __name__ == "__main__":
    main()
