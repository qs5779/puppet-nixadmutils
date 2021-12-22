#!/usr/bin/env python3
# -*- Mode: Python; tab-width: 2; indent-tabs-mode: nil -*-

from bs4 import BeautifulSoup
from datetime import datetime
import glob
import json
import logging
from optparse import OptionParser
import os
from pathlib import Path
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
    except Exception as e:
      self.__add_error('scrape_brainy_qod: %s' % str(e))

  def print_quote(self):
    try:
      self.__connect()

      if not self.options['cron']:

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

        cursor = self.dbconn.cursor()
        cursor.execute(query)
        row = cursor.fetchone()

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
      self.logger.info('%s (%d)', (key, self.notices[key]))
    for key in self.warnings:
      self.logger.warning('%s (%d)', (key, self.warnings[key]))
    for key in self.errors:
      self.logger.error('%s (%d)', (key, self.errors[key]))

def main():

  usage = "usage: %prog [options]"
  parser = OptionParser(usage)
  parser.add_option("-c", "--cron", action="store_true", dest="cron", default=0, help='specify executed from cron')
  parser.add_option("-d", "--debug", action="store_true", dest="debug", default=0, help='specify debug mode')
  parser.add_option("-V", "--version", action="store_true", dest="version", default=False, help='show version and exit')

  (opts, args) = parser.parse_args()

  options = vars(opts)

  if options['version']:
    print('%s Version: 3.0.0' % Path(sys.argv[0]).name)
    exit(0)

  qs = QuoteServer(options)
  qs.print_quote()

if __name__ == '__main__':
  main()
