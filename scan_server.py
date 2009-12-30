import os
import subprocess
import tornado.httpserver
import tornado.ioloop
import tornado.web
import tornado.escape
import re
import math

import scan_data
import dbm

db = dbm.open("scan_data", "c")

thumb_base_dir = "static/thumbnails"
pagesized_base_dir = "static/pagesized"
scanner_cmd = ["scanimage", "--mode", "color", "--format=tiff"]

def start_scan(filename):
  with open("temp.tiff", "w") as out:
    subprocess.Popen(scanner_cmd, stdout=out).communicate()
  subprocess.Popen(["convert", "temp.tiff", filename]).communicate()

  return open(filename)

base_resolution = (2544,3509)

def make_thumbnail(input, output, target_width):
  scale_factor = math.floor(base_resolution[0] / target_width)
  target_scale = (target_width, base_resolution[1] / scale_factor)
  subprocess.Popen(["convert", "-scale", "%dx%d" % target_scale, input, output]).communicate()

class PageHandler(tornado.web.RequestHandler):
  def get(self):
    "retrieve all pages"
    pages = []
    for key in db.keys():
      if key.startswith("page-"):
        pages.append(scan_data.read_page(key, db))

    pages_html = []
    for page in pages:
      pages_html.append("<img src=\"%s\" width=400 />" % page.filename)
    pages_html = "\n".join(pages_html)

    self.set_header("Content-Type", "text/html")
    self.write("""
    <html><head><title>All pages</title></head>
    <body>
    <h1>All Pages</h1>
    %(pages_html)s
    </body>
    </html>""" % locals())

  def get(self, page_key=None):
    "modify a specific page"

    if not page_key:
      return self.get()

    page = scan_data.read_page(page_key, db)

    doc = page.document()
    doc_name = doc.name
    filename = page.filename
    doc_key = doc.key()

    # where are we in the document?
    loc = filter(lambda x: page.key() == x[1].key(), enumerate(doc.pages()))
    index = loc[0][0] + 1
    n_pages = len(doc.pages())
    
    prev_link = ""
    next_link = ""
    if index > 1:
      prev_link = "<a href=\"/page/%s\">&lt&lt</a>" % doc.pages()[index-2].key()
    if index != n_pages:
      next_link = "<a href=\"/page/%s\">&gt&gt</a>" % doc.pages()[index].key()

    # build a page sized image if necessary
    if not os.path.isdir(pagesized_base_dir):
      os.mkdir(pagesized_base_dir)
    pagesized_path = "%s/%s.png" % (pagesized_base_dir, page.key())
    if not os.path.exists(pagesized_path):
      make_thumbnail(filename, pagesized_path, 1024)

    controls = """
    <a href="/document/%(doc_key)s">Back to Document</a><br/>
    <a href="/%(filename)s">Full resolution image</a><br/>
    %(prev_link)s &nbsp &nbsp &nbsp &nbsp %(next_link)s<br/>
    """ % locals()

    self.set_header("Content-Type", "text/html")
    self.write("""
    <html><head><title>%(doc_name)s page %(index)d of %(n_pages)d</title></head>
    <body>
    <h1>%(doc_name)s</h1>
    <h2>Page %(index)d of %(n_pages)d</h2>
    %(controls)s
    <hr/>
    <img src="/%(pagesized_path)s" />
    <hr/>
    %(controls)s
    </body>
    </html>""" % locals())

class ThumbnailHandler(tornado.web.RequestHandler):
  def get(self, page_key):
    # make sure directory exists
    if not os.path.isdir(thumb_base_dir):
      os.mkdir(thumb_base_dir)

    # if the file doesn't exist, create it
    thumbnail_path = "%s/%s.png" % (thumb_base_dir, page_key)
    if not os.path.exists(thumbnail_path):
      make_thumbnail("static/%s.png" % page_key, thumbnail_path, 400)

    # serve the thumbnail
    self.set_header("Content-Type", "image/png")
    f = open(thumbnail_path)
    self.write(f.read())

class DocumentHandler(tornado.web.RequestHandler):
  def single_get(self):
    "retrieve the list of documents"
    docs = []
    for key in db.keys():
      if key.startswith("document-"):
        docs.append(scan_data.read_document(key, db))
    docs.sort(key = lambda doc: doc.name)

    doc_html = []
    num_docs = len(docs)
    for doc in docs:
      pages = doc.pages()
      pages_str = "no pages"
      if len(pages) > 1:
        pages_str = "(%d pages)" % len(pages)
      elif len(pages) == 1:
        pages_str = "(1 page)"

      doc_html.append("<li><a href=\"/document/%s\">%s</a> %s</li>" % (doc.key(), doc.name, pages_str))
    doc_html = "\t" + "\n\t".join(doc_html)

    self.set_header("Content-Type", "text/html")
    self.write("""
    <html><head><title>Document List</title></head>
    <body>
    <h1>%(num_docs)d Documents</h1>
    <ul>
    %(doc_html)s
    </ul>
    <hr />
    <h2>Create New Document</h2>
    <form method="post" action="/documents">
      Name: <input name="name" type="text"/><br/>
      Tags: <input name="tags" type="text"/><br/>
      <input type="submit" value="Create Document" />
    </form>
    </html>""" % locals())

  def get(self, doc_key=None):
    "retrieve a specific document"

    if not doc_key:
      return self.single_get()

    doc = scan_data.read_document(doc_key, db)
    doc_name = doc.name
    pages = doc.pages()
    pages_html = []
    for page in pages:
      pages_html.append("<a href=\"/page/%s\"><img src=\"/thumbnail/%s\" /></a>" % (page.key(), page.key()))
    pages_html = "\n".join(pages_html)

    self.set_header("Content-Type", "text/html")
    self.write("""
    <html><head><title>Document: %(doc_name)s</title></head>
    <body>
    <h1>%(doc_name)s</h1>
    <a href="/documents">Back To All Documents</a><br/><br/>
    <form method="post">
      <input type="submit" value="Scan a Page" />
    </form>
    <hr/>
    %(pages_html)s
    <br/>
    <a href="/documents">Back To Documents</a>
    <br/><br/>
    <form method="post">
      <input type="submit" value="Scan a Page" />
    </form>
    </html>""" % locals())


  def single_post(self):
    "create a new document"

    name = self.get_argument("name")

    tag_re = re.compile("[\w,;]+")
    tags = self.get_argument("tags").split(" ")

    doc = scan_data.Document(db, name = name, tags = tags)
    scan_data.write_document(doc, db)
    self.redirect("/document/%s" % doc.key())

  def post(self, doc_key=None):
    "update a specific document"

    if not doc_key:
      return self.single_post()

    self.redirect("/scan/%s" % doc_key)
    

class ScanHandler(tornado.web.RequestHandler):
  def get(self, doc_id):
    doc = scan_data.read_document(doc_id, db)
    page = scan_data.Page(db, document=doc)
    page.filename = "static/%s.png" % page.key()

    img_pipe = start_scan(page.filename)
    self.set_header("Content-Type", "image/png")
    for chunk in img_pipe:
      self.write(chunk)

    scan_data.write_document(doc, db)

class MainHandler(tornado.web.RequestHandler):
  def get(self, doc_id=None):
    self.set_header("Content-Type", "text/html")
    self.write("""
    <html><head><title>Office Scanner</title></head>
    <body>
    <h3>Performing scan. Document will appear below when complete.</h3>
    <img src="/scan_%(doc_id)s.png" width=600/>
    <br/>
    <a href="/document/%(doc_id)s">Back to Document</a><br/>
    <form method="get">
      <input type="submit" value="Scan Another Page" />
    </form>
    
    </body>
    </html>""" % locals())

settings = {
    "static_path": os.path.join(os.path.dirname(__file__), "static")
}

application = tornado.web.Application([
    (r"/scan/([^/]+)", MainHandler),
    (r"/scan_([^/]+).png", ScanHandler),
    (r"/documents", DocumentHandler),
    (r"/", DocumentHandler),
    (r"/document/([^/]+)", DocumentHandler),
    (r"/pages", PageHandler),
    (r"/page/([^/]+)", PageHandler),
    (r"/thumbnail/([^/]+)", ThumbnailHandler),
], **settings)

if __name__ == "__main__":
  http_server = tornado.httpserver.HTTPServer(application)
  http_server.listen(8000)
  tornado.ioloop.IOLoop.instance().start()
  db.close()
