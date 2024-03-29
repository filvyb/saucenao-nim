import std/options
import std/json
import std/httpclient
import std/asyncdispatch
import std/asyncstreams
import std/times
import std/strutils

import enums
import errors
import containers

export enums
export errors
export containers

let sauceNaoUrl = "https://saucenao.com/search.php"

type
  SauceNao = object of RootObj
    key: Option[string]
    testmode*: int
    dbmask*: Option[int]
    dbmaski*: Option[int]
    db*: Option[DBs]
    dbs*: Option[seq[DBs]]
    numres*: int
    dedupe*: Option[Dedupe]
    hide*: Option[Hide]
    last_used: Time
    short_remaining: int
    long_remaining: int
  SauceNaoRef = object of ref SauceNao

## Initializes and object containing your API key and your search settings
proc initSauceNao*(key=none string, testmode=0, dbmask=none int, dbmaski=none int,
                  db=none DBs, dbs=none seq[DBs], numres=8, dedupe=none Dedupe,
                  hide=none Hide): SauceNao =
  if dbmask.isSome and dbmaski.isSome:
    raise newException(SauceNaoApiError, "Using dbmask and dbmaski is redundant")

  if (dbmask.isSome or dbmaski.isSome) and db.isSome:
    raise newException(SauceNaoApiError, "Using db and masks")

  if db.isSome and dbs.isSome:
    raise newException(SauceNaoApiError, "Using db and dbs is redundant")

  result.key = key
  result.testmode = testmode
  result.dbmask = dbmask
  result.dbmaski = dbmaski
  result.db = db
  result.dbs = dbs
  result.numres = numres
  result.dedupe = dedupe
  result.hide = hide
  result.last_used = getTime()
  result.short_remaining = 4
  result.long_remaining = 100

proc newSauceNao*(key=none string, testmode=0, dbmask=none int, dbmaski=none int,
                  db=none DBs, dbs=none seq[DBs], numres=8, dedupe=none Dedupe,
                  hide=none Hide): SauceNaoRef =
  if dbmask.isSome and dbmaski.isSome:
    raise newException(SauceNaoApiError, "Using dbmask and dbmaski is redundant")

  if (dbmask.isSome or dbmaski.isSome) and db.isSome:
    raise newException(SauceNaoApiError, "Using db and masks")

  if db.isSome and dbs.isSome:
    raise newException(SauceNaoApiError, "Using db and dbs is redundant")

  result.key = key
  result.testmode = testmode
  result.dbmask = dbmask
  result.dbmaski = dbmaski
  result.db = db
  result.dbs = dbs
  result.numres = numres
  result.dedupe = dedupe
  result.hide = hide
  result.last_used = getTime()
  result.short_remaining = 4
  result.long_remaining = 100

proc createUrl(self: ptr SauceNao, url="", filepath=""): (string, MultipartData) =
  if url != "" and filepath != "":
    raise newException(UrlAndFileError, "Can't search for file and URL at the same time")

  if self.short_remaining <= 0 and (getTime() - self.last_used) < initDuration(seconds=30):
    raise newException(ShortLimitReachedError, "Short limit reached")
  if self.long_remaining <= 0 and (getTime() - self.last_used) < initDuration(hours=24):
    raise newException(LongLimitReachedError, "Long limit reached")

  var data = newMultipartData()
  var urlArgs = ""

  if self.key.isSome:
    urlArgs &= "&api_key=" & self.key.get()

  if self.dbmask.isSome:
    urlArgs &= "&dbmask=" & $self.dbmask.get()
  if self.dbmaski.isSome:
    urlArgs &= "&dbmask=" & $self.dbmaski.get()

  if self.dbs.isSome:
    for d in self.dbs.get():
      urlArgs &= "&dbs[]=" & $ord(d)
  if self.db.isSome:
    urlArgs &= "&db=" & $ord(self.db.get())
  urlArgs &= "&numres=" & $self.numres

  if self.dedupe.isSome:
    urlArgs &= "&dedupe=" & $ord(self.dedupe.get())

  if self.hide.isSome:
    urlArgs &= "&hide=" & $ord(self.hide.get())

  if url != "":
    urlArgs &= "&url=" & url

  urlArgs &= "&output_type=" & "2"

  if filepath != "":
    data.addFiles({"file": filepath})

  urlArgs[0] = '?'
  var resUrl = sauceNaoUrl & urlArgs

  return (resUrl, data)

proc processData(self: ptr SauceNao, url="", filepath=""): MultipartData =
  if url != "" and filepath != "":
    raise newException(UrlAndFileError, "Can't search for file and URL at the same time")

  if self.short_remaining <= 0 and (getTime() - self.last_used) < initDuration(seconds=30):
    raise newException(ShortLimitReachedError, "Short limit reached")
  if self.long_remaining <= 0 and (getTime() - self.last_used) < initDuration(hours=24):
    raise newException(LongLimitReachedError, "Long limit reached")

  var data = newMultipartData()
  
  if self.key.isSome:
    data["api_key"] = self.key.get()

  if self.dbmask.isSome:
    data["dbmask"] = $self.dbmask.get()
  if self.dbmaski.isSome:
    data["dbmaski"] = $self.dbmaski.get()

  #var tmpseq: seq[int]
  #for d in self.dbs:
  #  tmpseq &= ord(d)
  #data["dbs"] = $(%tmpseq)
  if self.db.isSome:
    data["db"] = $ord(self.db.get())
  data["numres"] = $self.numres

  if self.dedupe.isSome:
    data["dedupe"] = $ord(self.dedupe.get())

  if self.hide.isSome:
    data["hide"] = $ord(self.hide.get())

  if url != "":
    data["url"] = url

  data["output_type"] = "2"

  if filepath != "":
    data.addFiles({"file": filepath})

  return data

proc parseResponse(self: ptr SauceNao, status_code: HttpCode, body: string): NaoResponse =
  var s = cast[int](status_code)

  if s == 200:
    let p = parseJson(body)

    var main_header = p["header"]
    var status = main_header["status"].getInt()
    var user_id = parseInt(main_header["user_id"].getStr("-6"))

    if status < 0:
      raise newException(UnknownClientError, "Unknown client error")
    elif status > 0:
      raise newException(UnknownServerError, "Unknown API error")
    elif user_id < 0:
      raise newException(UnknownServerError, "Unknown API error")
    elif user_id == 0 and self.key.isSome:
      raise newException(BadKeyError, "Invalid API key")

    self.long_remaining = main_header["long_remaining"].getInt()
    self.short_remaining = main_header["short_remaining"].getInt()
    self.last_used = getTime()

    result = initNaoResponse(p)
    

  elif s == 403:
    raise newException(AnonymousAccessError, "Anonymous API usage not permited")
  elif s == 413:
    raise newException(BadFileSizeError, "File is too big")
  elif s == 429:
    let p = parseJson(body)
    var t = p["header"]["message"]
    if "Daily" in t.getStr():
      raise newException(LongLimitReachedError, "24 hours limit reached")
    else:
      raise newException(ShortLimitReachedError, "30 second limit reached")
  else:
    raise newException(UnknownApiError, "Uknown error")

proc search(self: var SauceNao, url="", filepath=""): NaoResponse =
  var cap = self.addr
  # You have to use URL?? huh
  #var data = cap.processData(url, filepath)
  var tmp = cap.createUrl(url, filepath)
  var sauceNaoUrl = tmp[0]
  var data = tmp[1]

  #echo sauceNaoUrl

  var client = newHttpClient()

  client.headers = newHttpHeaders({ "Content-Type": "application/json" })

  let response = client.post(sauceNaoUrl, multipart = data)
  result = cap.parseResponse(response.code(), response.body)

proc asyncSearch(self: ptr SauceNao, url="", filepath=""): Future[NaoResponse] {.async.} =
  # You have to use URL?? huh
  #var data = self.processData(url, filepath)
  var tmp = self.createUrl(url, filepath)
  var sauceNaoUrl = tmp[0]
  var data = tmp[1]

  var client = newAsyncHttpClient()

  client.headers = newHttpHeaders({ "Content-Type": "application/json" })

  var response = await client.post(sauceNaoUrl, multipart = data)

  var o = await readAll(response.bodyStream)

  if o.len == 0:
    raise newException(UnknownServerError, "Failed retrieving response")

  result = self.parseResponse(response.code(), o)


proc fromFile*(self: var SauceNao, filepath: string): NaoResponse =
  result = self.search(filepath=filepath)

proc fromUrl*(self: var SauceNao, url: string): NaoResponse =
  result = self.search(url=url)

proc asyncFromFile*(self: ptr SauceNao, filepath: string): Future[NaoResponse] {.async.} =
  result = await self.asyncSearch(filepath=filepath)

proc asyncFromUrl*(self: ptr SauceNao, url: string): Future[NaoResponse] {.async.} =
  result = await self.asyncSearch(url=url)
