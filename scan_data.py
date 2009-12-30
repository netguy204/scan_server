import dbm
import pickle
import uuid
import copy

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

  def add_page(self, page):
    page.set_document(self)

    if not hasattr(self, "_pages"):
      self.pages()

    self._pages.append(page)

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
    self._document = doc

  def document(self):
    if not hasattr(self, "_document"):
      self._document = None

    if hasattr(self, "_document_key"):
      self._document = read_document(self._document_key, self.db)
      del self._document_key

    return self._document

  def indices(self):
    return [(self.filename, self.key())]

def read_page(key, db):
  if not key in db:
    raise Exception("key %s is not in database" % key)

  page = pickle.loads(db[key])
  page.db = db
  return page

def read_document(key, db):
  if not key in db:
    raise Exception("key %s is not in database" % key)

  doc = pickle.loads(db[key])
  doc.db = db
  return doc

def read_tag(tag, db):
  if not tag in db:
    return []

  results = []
  for item_key in pickle.loads(db[tag]):
    item = pickle.loads(db[item_key])
    item.db = db
    results.append(item)
  return results

def write_document(doc, db):
  # we change doc to make it serialize efficiently with its indices
  # so we make a copy to not mess up what the user gave us
  _doc = copy.copy(doc)
  pages = _doc.pages()
  del _doc._pages
  del _doc.db

  # turn the pages into page keys
  _doc._page_keys = [ page.key() for page in pages ]

  # if the old document exists, retrieve it so we can remove its indices
  # later
  old_doc = None
  if _doc.key() in db:
    old_doc = pickle.loads(db[_doc.key()])

  # save the actual document and it's page keys
  db[_doc.key()] = pickle.dumps(_doc)

  # save the pages
  for page in pages:
    _page = copy.copy(page)
    _page._document_key = _page.document().key()
    del _page._document
    del _page.db
    db[_page.key()] = pickle.dumps(_page)

  # re-write the indices
  if old_doc:
    for ind in old_doc.indices():
      entries = pickle.loads(db[ind[0]])
      entries.remove(ind[1])
      db[ind[0]] = pickle.dumps(entries)

  for ind in _doc.indices():
    if not ind[0] in db:
      print "first entry for %s" % ind[0]
      db[ind[0]] = pickle.dumps([ ind[1] ])
    else:
      print "adding entry for %s" % ind[0]
      entries = pickle.loads(db[ind[0]])
      entries.append(ind[1])
      db[ind[0]] = pickle.dumps(entries)

# the test
if __name__ == "__main__":
  db = dbm.open("test", "c")

  d = Document(db, name="mortage-statement", tags=["bill", "important", "home"])
  p1 = Page(db, filename="file1", document=d)
  p2 = Page(db, filename="file2", document=d)

  write_document(d, db)


  print "Document"
  print db[d.key()]

  print "Tag 'bill'"
  print db[Document.TAG_PRE + "bill"]

  print "De-serialized document"
  print "Result: %s" % read_document(d.key(), db)

  print "De-serialized tag"
  for item in read_tag(Document.TAG_PRE + "bill", db):
    print "Item: %s" % item

  db.close()
