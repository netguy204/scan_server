#!/usr/bin/env python
# Copyright 2010, Brian Taylor
# Distributed under the GNU General Public License

# utility for migrating data from a dbm based store to a mongodb based store

import os
import sys
import dbm
import scan_data
import pymongo
import json

def main(args):
  db = dbm.open("scan_data", "r")
  print "loaded database"

  mdb = pymongo.Connection()
  print "connected to mongo"

  docs = scan_data.get_documents(db)
  print "loaded %d documents" % len(docs)

  mdb_docs = mdb.scanserver.documents

  # go through each document and build a set of pagekeys
  pagekeys = set()
  for doc in docs:
    docstr = scan_data.doc2json(doc)
    pagekeys.update( [ page.key() for page in doc.pages() ] )
    mdb_docs.insert(docstr)

  print "found %d pages" % len(pagekeys)

  mdb_pages = mdb.scanserver.pages

  for pk in pagekeys:
    page = scan_data.read_page(pk, db)
    pagestr = scan_data.page2json(page)
    mdb_pages.insert(pagestr)

  dirpks = set()
  for (base, dirs, files) in os.walk("static",  topdown=True):
    # don't recurse any further
    del dirs[0:-1]

    for fname in files:
      pk = os.path.splitext(fname)[0]
      if pk.startswith("page-"):
        dirpks.add(pk)

  notindb = dirpks - pagekeys
  print "found %d page keys on disk that aren't in the database" % len(notindb)

if __name__ == "__main__":
  sys.exit( main(sys.argv[1:]) )
