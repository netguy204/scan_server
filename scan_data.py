#!/usr/bin/env python
# Copyright 2009, Brian Taylor
# Distributed under the GNU General Public License

# data model for scan_server

import dbm
import json
import uuid
import copy
import pymongo

from functools import partial

class Document:
  NAME_PRE = "N-"
  TAG_PRE = "T-"

  def __init__(self, db, name=None, tags=None, pages=None):
    self.db = db
    self.name = name
    self.tags = tags

    self._pages = []
    if pages:
      for page in pages:
        self.add_page(page)

    self._key = "document-%s" % uuid.uuid4()

  def pages(self):
    if not hasattr(self, "_pages"):
      self._pages = []

    if hasattr(self, "_page_keys"):
      for key in self._page_keys:
        self._pages.append(read_page(key, self.db))
      del self._page_keys

    return self._pages

  def ensure_pages(self):
    if not hasattr(self, "_pages"):
      self.pages()

  def add_page(self, page):
    self.ensure_pages()
    page.set_document(self)
    self._pages.append(page)

  def remove_page(self, page):
    thePage = None
    for aPage in self.pages():
      if aPage.key() == page.key():
        thePage = aPage
        self._pages.remove(aPage)
        break
    return thePage
    
  def key(self):
    return self._key

  def indices(self):
    ind = []

    if self.name:
      ind.append( (Document.NAME_PRE + self.name, self.key()) )
    if self.tags:
      for tag in self.tags:
        ind.append( (Document.TAG_PRE + tag, self.key()) )

    return ind

  def __str__(self):
    return "Document(%s, %d pages)" % (self.name, len(self.pages()))

class Page:
  def __init__(self, db, filename=None, document=None):
    self.db = db
    self.filename = filename
    self._key = "page-%s" % uuid.uuid4()

    if document:
      document.add_page(self)

  def key(self):
    return self._key

  def set_document(self, doc):
    if not doc:
      self._document_key = None

    self._document = doc

  def document(self):
    if not hasattr(self, "_document"):
      self._document = None

    if hasattr(self, "_document_key"):
      if not self._document_key:
        return None

      self._document = read_document(self._document_key, self.db)
      del self._document_key

    return self._document

  def indices(self):
    return [(self.filename, self.key())]

def get_documents(db):
    docs = []
    mdb_docs = db.documents
    for entry in mdb_docs.find(fields=["_id"]):
      docs.append(read_document(entry["_id"], db))

    docs.sort(key = lambda doc: doc.name)
    return docs

def remove_page(key, db):
  page = read_page(key, db)
  doc = page.document()

  if doc:
    if not doc.remove_page(page):
      print "couldn't find page in doc"
      return None

    write_document(doc, db)
    return True
  print "couldn't find doc"
  return None

def read_page(key, db):
  mdb_pages = db.pages
  page = mdb_pages.find_one({"_id" : key})
  if not page:
    raise Exception("key %s is not in database" % key)

  pageobj = Page(db, filename=page['filename'])
  pageobj._document_key = page['document']
  pageobj._key = page['_id']

  return pageobj

def read_document(key, db):
  mdb_docs = db.documents
  doc = mdb_docs.find_one({"_id" : key})
  if not key:
    raise Exception("key %s is not in database" % key)

  docobj = Document(db, name=doc['name'], tags=doc['tags'])
  docobj._page_keys = doc['pages']
  docobj._key = doc['_id']
  return docobj

# TODO: merge with _to_json functions in scan server
def doc2json(doc):
  data = {}
  data['_id'] = doc.key()
  data['pages'] = [ page.key() for page in doc.pages() ]
  data['name'] = doc.name
  data['tags'] = doc.tags or []

  return data

def page2json(page):
  data = {}
  data['_id'] = page.key()
  data['document'] = page.document() and page.document().key()
  data['filename'] = page.filename

  return data

def write_document(doc, db):
  mdb_docs = db.documents

  # save the document
  mdb_docs.save(doc2json(doc))

  # save the pages
  for page in doc.pages():
    write_page(page, db)

def write_page(page, db):
  mdb_pages = db.pages
  mdb_pages.save(page2json(page))

# the test
if __name__ == "__main__":
  db = pymongo.Connection().test

  tags = ["bill", "important", "home"]
  d = Document(db, name="mortage-statement", tags=tags)
  p1 = Page(db, filename="file1", document=d)
  p2 = Page(db, filename="file2", document=d)

  assert(d.tags == tags)
  write_document(d, db)

  print "De-serialized document"
  doc = read_document(d.key(), db)
  assert(doc.tags == tags)
  print "Result: %s" % doc
  for page in doc.pages():
    print page.key(), "->", page.filename

  p3 = Page(db, filename="another", document=doc)
  assert(len(doc.pages()) == 3)
  write_document(doc, db)
  doc = read_document(doc.key(), db)
  assert(len(doc.pages()) == 3)
  assert(doc.tags == tags)

  #print "De-serialized tag"
  #for item in read_tag(Document.TAG_PRE + "bill", db):
  #  print "Item: %s" % item

