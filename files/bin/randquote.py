#!/usr/bin/env python3
# -*- Mode: Python; tab-width: 2; indent-tabs-mode: nil -*-

from bs4 import BeautifulSoup
from datetime import datetime
import glob
import hashlib
import json
import logging
from optparse import OptionParser
import os
from pathlib import Path
# import pprint
from random import randrange
import re
import requests
import shutil
import sqlite3

class QuoteServer():
  def __init__(self, options):
    self.DBVERSION = '1'
    self.DBDIRECTORY = Path('/opt/nixadmutils/var')
    self.notices = {}
    self.warnings = {}
    self.errors = {}
    self.options = options

    try:
      if not Path.is_dir(self.DBDIRECTORY):
        Path.mkdir(self.DBDIRECTORY, parents=True)
      logname = self.DBDIRECTORY / 'randomquotes.log'
      self.dbfilenm = self.DBDIRECTORY / 'randomquotes.sqlite'
      s_logname = str(logname)
      if options['debug']:
        llevel = logging.DEBUG
      else:
        llevel = logging.INFO

      if not logname.exists():
        logname.touch()
        shutil.chown(s_logname, group='users')
        os.chmod(s_logname, 0o664)

      logging.basicConfig(filename=s_logname,
                            filemode='a',
                            format='%(asctime)s %(name)s %(levelname)s %(message)s',
                            datefmt='%H:%M:%S',
                            level=llevel)

      # logging.info("Running Quote Server")

      self.logger = logging.getLogger('QuoteServer')

      self.logger.info("Started.")
      self.dbconn = None
      self.regex_unknown = re.compile('unknown', re.IGNORECASE)

    except Exception as e:
      raise

  def __yes_or_no(self, question):
    reply = str(input(question+' (Y/n): ')).lower().strip()
    if (reply == '') or (reply[0] == 'y'):
        return True
    return False

  def __today(self):
    return datetime.now().strftime('%Y%m%d')

  def __create_quote_database(self):
    connection = sqlite3.connect(self.dbfilenm)
    cursor = connection.cursor()
    cursor.execute('''CREATE TABLE qdbinfo (name TEXT PRIMARY KEY, value TEXT);''')
    # connection.commit()

    cursor.execute("INSERT INTO qdbinfo (name,value) VALUES ('version', '%s');" % self.DBVERSION)
    cursor.execute("INSERT INTO qdbinfo (name,value) VALUES ('scraped', '%s');" % 0)
    # connection.commit()

    cursor.execute('''CREATE TABLE authors (
      author_id integer PRIMARY KEY,
      author_name text UNIQUE NOT NULL
    );''')
    # connection.commit()

    cursor.execute('''CREATE TABLE categories (
      category_id integer PRIMARY KEY,
      category text UNIQUE NOT NULL
    );''')
    # connection.commit()

    cursor.execute('''CREATE TABLE quotes (
      quote_id integer PRIMARY KEY,
      author_id integer,
      category_id integer,
      quote text UNIQUE NOT NULL,
      used integer,
      FOREIGN KEY (author_id)
        REFERENCES authors (author_id),
      FOREIGN KEY (category_id)
        REFERENCES authors (category_id)
    );''')
    self.dbconn = connection
    self.__commit()
    self.__import_quotes()
    s_dbfilenm = str(self.dbfilenm)
    shutil.chown(s_dbfilenm, group='users')
    os.chmod(s_dbfilenm, 0o664)

  def __commit(self):
    self.dbconn.commit()

  def __update_quote_database(self):
    connection = sqlite3.connect(self.dbfilenm)
    # check that version is current
    self.dbconn = connection

  def __add_author(self, author):
    if re.search(self.regex_unknown, author):
      author = 'Author Unknown'

    query = '''SELECT author_id FROM authors WHERE author_name = ?'''
    cursor = self.dbconn.cursor()
    cursor.execute(query, (author,))
    row = cursor.fetchone()
    if not row:
      query = '''INSERT INTO authors (author_name) VALUES(?)'''
      cursor.execute(query,(author,))
      aid = cursor.lastrowid
      self.__commit()
    else:
      aid = row[0]
    return aid

  def __add_category(self, category = 'None'):
    query = '''SELECT category_id FROM categories WHERE category = ?'''
    cursor = self.dbconn.cursor()
    cursor.execute(query, (category,))
    row = cursor.fetchone()
    if not row:
      query = '''INSERT INTO categories (category) VALUES(?)'''
      cursor.execute(query,(category,))
      cid = cursor.lastrowid
      self.__commit()
    else:
      cid = row[0]
    return cid

  def __add_quote(self, author, quote, used = 0, category = 'None'):
    query = '''SELECT quote_id FROM quotes WHERE quote = ?'''
    cursor = self.dbconn.cursor()
    cursor.execute(query, (quote,))
    row = cursor.fetchone()
    if row is None:
      cid = self.__add_category(category)
      aid = self.__add_author(author)
      query = '''INSERT INTO quotes (category_id, author_id, quote, used) VALUES (?,?,?,?)'''
      cursor.execute(query, (cid, aid, quote, int(used),))
      self.__commit()
    else:
      notice = 'duplicate: %a' % quote
      if notice in self.notices:
        self.notices[notice] += 1
      else:
        self.notices[notice] = 1

  def __import_quotes_from(self, qfp):
    if qfp.is_file():
      with open(qfp) as infile:
        quotes = json.load(infile)
      for key in quotes:
        self.__add_quote(quotes[key]['author'], quotes[key]['quote'], quotes[key]['used'])

  def __import_quotes(self):
    mask = str(self.DBDIRECTORY / '20*-andiquote.json')
    for name in glob.glob(mask):
      self.__import_quotes_from(Path(name))

  def __connect(self):
    if self.dbconn is None:
      if not Path.exists(self.dbfilenm):
        self.__create_quote_database()
      else:
        self.__update_quote_database()
      if self.__scrape():
        self.__scrape_brainy_qod()
        self.__scraped()

  def __add_notice(self, notice):
    if notice in self.notices:
      self.notices[notice] += 1
    else:
      self.notices[notice] = 1

  def __add_error(self, message):
      if message in self.errors:
        self.errors[message] += 1
      else:
        self.errors[message] = 1

  def __scraped(self):
    query = '''INSERT OR REPLACE INTO qdbinfo (name, value) VALUES(?, ?)'''
    cursor = self.dbconn.cursor()
    cursor.execute(query, ('scraped', self.__today()))
    self.__commit()

  def __scrape(self):
    query = '''SELECT value FROM qdbinfo WHERE name = ?'''
    cursor = self.dbconn.cursor()
    cursor.execute(query, ('scraped',))
    row = cursor.fetchone()
    if row:
      last = row[0]
    else:
      last = 0
    return int(self.__today()) > int(last)

  def __scrape_inspiringquotes(self, url, author, category):
    md5sum = hashlib.md5(url.encode('utf-8')).hexdigest()
    cache = Path("/tmp/%s.html" % md5sum)
    quotes = {}
    if cache.exists():
      with open(cache, 'r') as f:
        response_data = f.read()
    else:
      response_data = requests.get(url).text[:]
      with open(cache, 'w') as f:
        f.write(response_data)
    soup = BeautifulSoup(response_data, 'html.parser')
    for bq in soup.find_all("blockquote"):
      # sbq = str(bq)
      # print(sbq)
      e_quote = bq.get_text().strip()
      em = bq.find("em")
      if em:
        e_author = em.get_text().strip()
        e_quote = e_quote.replace(e_author, '')
      else:
        e_author = author

      e_quote = e_quote.replace(' / ', '')
      if e_author:
        e_author = re.sub(r",.*", '', e_author)
        e_author = re.sub(r"^[^A-Za-z]+", '', e_author)
      if e_quote in quotes:
        quotes[e_quote]['count'] += 1
      else:
        quotes[e_quote] = {}
        quotes[e_quote]['count'] = 1
        quotes[e_quote]['author'] = e_author
        quotes[e_quote]['category'] = category
    return quotes

  def __scrape_brainy_qod(self):
    url = 'https://www.brainyquote.com/quote_of_the_day'
    try:
      response_data = requests.get(url).text[:]
      soup = BeautifulSoup(response_data, 'html.parser')
      display = re.compile('^display:')
      # <div class="grid-item qb clearfix bqQt">
      qnbr = scraped = failed = 0
      for item in soup.find_all("div", class_="grid-item qb clearfix bqQt"):
        # print(item)
        # <h2 class="qotd-h2">Funny Quote Of the Day</h2>
        qnbr += 1
        category = item.find("h2",class_="qotd-h2")
        if category:
          tcategory = category.get_text().strip()
          self.logger.debug('category: %s' % tcategory)
        else:
          tcategory = 'None'
        # <div style="display: flex;justify-content: space-between">
        quote = item.find("div", { "style" : display })
        if quote:
          tquote = quote.get_text().strip()
          self.logger.debug('quote: %s' % tquote)
        else:
          self.logger.warning('Scrape quote number %d failed.' % qnbr)
          failed += 1
          continue
        # <a href="/authors/jonathan-swift-quotes" class="bq-aut qa_155269 oncl_a" title="view author">Jonathan Swift</a>
        author = item.find("a", {"title" : "view author"})
        if author:
          tauthor = author.get_text().strip()
          self.logger.debug('author: %s' % tauthor)
        else:
          self.logger.warning('Scrape author number %d failed.' % qnbr)
          failed += 1
          continue
        self.__add_quote(tauthor, tquote, '0', tcategory)
        scraped += 1
      if (sys.stdout.isatty()) and (scraped > 0):
        print("Added %d brainy quotes of the day to database." % scraped)
    except Exception as e:
      self.__add_error('scrape_brainy_qod: %s' % str(e))

  def parse_url(self, url, author, category):
    if not author:
      author = 'unknown'
    if not category:
      category = 'None'
    if not re.match('^http[s]*://', url):
      url = 'https://' + url
    if self.options['debug']:
      print('url: %s' % url)
      print('author: %s' % author)
      print('category: %s' % category)
    if re.search('inspiringquotes.com', url):
      quotes = self.__scrape_inspiringquotes(url, author, category)
    else:
      match = re.search(r"^http[s]*://([^/]+)", url)
      if match:
        tgt = match.group(1)
      else:
        tgt = url
      print("Unrecognized site: %s" % tgt)
      return 0
    extracted = len(quotes)
    if extracted > 0:
      for qq in quotes:
        print('''quote: "%s"''' % qq)
        print('''author: "%s"''' % quotes[qq]['author'])
        print('''category: "%s"''' % quotes[qq]['category'])
        print('count: %d' % quotes[qq]['count'])
      answer = self.__yes_or_no("Import the quotes?")
      if answer:
        qnbr = 0
        self.__connect()
        for qq in quotes:
          self.__add_quote(quotes[qq]['author'], qq, 0, quotes[qq]['category'])
          qnbr += 1
        print("Added %d quotes to database." % qnbr)

  def __get_random_never_used(self, cursor):

    query = '''SELECT COUNT(*) FROM quotes WHERE quotes.used < 1'''
    cursor.execute(query)
    crow = cursor.fetchone()
    numrows = crow[0]
    if numrows > 0:
      query = '''SELECT
                    quotes.quote_id AS qid,
                    quotes.quote AS quote,
                    authors.author_name AS author,
                    categories.category AS category,
                    quotes.used AS used
                  FROM quotes
                  LEFT JOIN authors ON quotes.author_id = authors.author_id
                  LEFT JOIN categories ON quotes.category_id = categories.category_id
                  WHERE quotes.used < 1;
                    '''
      randrow = randrange(0, numrows)
      if self.options['verbose']:
        print('unused: %d' % numrows)
        print('randrow: %d' % randrow)
      idx = 0
      for row in cursor:
        if idx == randrow:
          return row
        idx += 1
    return None

  def __get_least_used(self, cursor):

    query = '''SELECT
                  quotes.quote_id AS qid,
                  quotes.quote AS quote,
                  authors.author_name AS author,
                  categories.category AS category,
                  quotes.used AS used
                FROM quotes
                LEFT JOIN authors ON quotes.author_id = authors.author_id
                LEFT JOIN categories ON quotes.category_id = categories.category_id
                ORDER BY quotes.used ASC LIMIT 1;
                '''

    cursor.execute(query)
    return cursor.fetchone()

  def print_quote(self):
    try:
      self.__connect()

      if not self.options['cron']:

        cursor = self.dbconn.cursor()

        row = self.__get_random_never_used(cursor)
        if not row:
          row = self.__get_least_used(cursor)
        if row:
          qid, quote, author, category, used = row
          query = '''UPDATE quotes SET used = used + 1 WHERE quote_id = ?'''
          cursor.execute(query, (qid,))
          self.__commit()
        else:
          quote = '"The phoenix must burn to emerge."'
          author = 'Janet Fitch'

        print('%s - %s' % (quote, author))

    except Exception as e:
      self.__add_error(str(e))

    for key in self.notices:
      self.logger.info('%s (%d)' % (key, self.notices[key]))
    for key in self.warnings:
      self.logger.warning('%s (%d)' % (key, self.warnings[key]))
    for key in self.errors:
      self.logger.error('%s (%d)' % (key, self.errors[key]))

def main():

  usage = "usage: %prog [options]"
  parser = OptionParser(usage)
  parser.add_option("-a", "--author", action="store", dest="author", default=False, help='optional category when parsing')
  parser.add_option("-c", "--cron", action="store_true", dest="cron", default=0, help='specify executed from cron')
  parser.add_option("-C", "--catagory", action="store", dest="category", default=False, help='optional category when parsing')
  parser.add_option("-d", "--debug", action="store_true", dest="debug", default=0, help='specify debug mode')
  parser.add_option("-p", "--url", action="store", dest="url", default=False, help='specify parse and add url')
  parser.add_option("-v", "--verbose", action="store_true", dest="verbose", default=0, help='specify verbose mode')
  parser.add_option("-V", "--version", action="store_true", dest="version", default=False, help='show version and exit')

  (opts, args) = parser.parse_args()

  options = vars(opts)

  if options['debug']:
    print('opts: %s' % opts)
    print('args: %s' % args)

  if options['version']:
    print('%s Version: 3.0.0' % Path(sys.argv[0]).name)
    exit(0)

  qs = QuoteServer(options)
  if opts.url:
    qs.parse_url(opts.url, opts.author, opts.category)
  else:
    qs.print_quote()

if __name__ == '__main__':
  main()
