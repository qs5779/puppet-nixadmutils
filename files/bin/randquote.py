#!/usr/bin/env python3
# -*- Mode: Python; tab-width: 2; indent-tabs-mode: nil -*-

import os
import sys
import json
import datetime
import shutil
import feedparser
from optparse import OptionParser

def load_quotes(fpn):
  if os.path.isfile(fpn):
    with open(fpn) as infile:
      q = json.load(infile)
  else:
    NewsFeed = feedparser.parse('https://andiquote.org/rss.php')
    count = 0
    q = {}
    for entry in NewsFeed.entries:
      count += 1
      idx = "%04d" % count
      q[idx] = {}
      q[idx]['author'] = entry['description']
      q[idx]['quote'] = entry['title']
      q[idx]['used'] = 0
  return q

def next_quote(quotes):
  mval = 99999
  mkey = False
  for key in quotes:
    if quotes[key]['used'] < mval:
      mkey = key
      mval = quotes[key]['used']
  return mkey

def main():
  usage = "usage: %prog [options]"
  parser = OptionParser(usage)
  parser.add_option("-d", "--debug", action="store_true", dest="debug", default=0, help='specify debug mode')
  parser.add_option("-V", "--version", action="store_true", dest="version", default=False, help='show version and exit')

  (opts, args) = parser.parse_args()

  options = vars(opts)

  if options['version']:
    basenm = os.path.basename(sys.argv[0])
    print('%s Version: 2.0.0' % basenm)
    exit(0)

  try:
    today = datetime.datetime.now().strftime("%Y%m%d")
    qfn = '/opt/nixadmutils/var/%s-andiquote.json' % today
    quotes = load_quotes(qfn)
    # print(json.dumps(quotes, indent=2))
    nq = next_quote(quotes)
    # print(nq)
    quote = quotes[nq]['quote']
    author = quotes[nq]['author']
    quotes[nq]['used'] += 1
    with open(qfn, "w") as outfile:
      json.dump(quotes, outfile)
    failure = False
  except:
    if options['debug']:
      print("Unexpected error:", sys.exc_info()[0])
    failure = True

  if failure:
    quote = '"The phoenix must burn to emerge."'
    author = 'Janet Fitch'

  print('%s - %s' % (quote, author))

if __name__ == "__main__":
    main()
