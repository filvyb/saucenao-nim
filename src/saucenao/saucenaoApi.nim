import std/options
import std/json
import std/httpclient
import std/asyncdispatch
import std/streams
import std/strformat
import std/times

import enums
import errors

let sauceNaoUrl = "https://saucenao.com/search.php"

type
  SauceNao = object of RootObj
    key: Option[string]
    testmode: int
    dbmask: Option[int]
    dbmaski: Option[int]
    dbs: seq[DBs]
    numres: int
    dedupe: Option[Dedupe]
    hide: Option[Hide]
    last_used: Time
    short_remaining: int
    long_remaining: int
  SauceNaoRef = object of ref SauceNao

proc initSauceNao*(key=none string, testmode=0, dbmask=none int, dbmaski=none int,
                  dbs=(@[DBs.All]), numres=8, dedupe=none Dedupe, hide=none Hide): SauceNao =
  result.key = key
  result.testmode = testmode
  result.dbmask = dbmask
  result.dbmaski = dbmaski
  result.dbs = dbs
  result.numres = numres
  result.dedupe = dedupe
  result.hide = hide
  result.last_used = getTime()
  result.short_remaining = 4
  result.long_remaining = 100

proc newSauceNao*(key=none string, testmode=0, dbmask=none int, dbmaski=none int,
                  dbs=(@[DBs.All]), numres=8, dedupe=none Dedupe, hide=none Hide): SauceNaoRef =
  result.key = key
  result.testmode = testmode
  result.dbmask = dbmask
  result.dbmaski = dbmaski
  result.dbs = dbs
  result.numres = numres
  result.dedupe = dedupe
  result.hide = hide
  result.last_used = getTime()
  result.short_remaining = 4
  result.long_remaining = 100

proc processData(self: SauceNao, url="", filepath=""): MultipartData =
  if url != "" and filepath != "":
    raise newException(UrlAndFileError, "Can't search for file and URL at the same time")

  if self.short_remaining <= 0 and (getTime() - self.last_used) < initDuration(seconds=30):
    raise newException(ShortLimitReachedError, "Short limit reached")
  if self.long_remaining <= 0 and (getTime() - self.last_used) < initDuration(days=30):
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
  #data["dbs"] = %tmpseq
  data["db"] = $999
  data["numres"] = $self.numres

  if self.dedupe.isSome:
    data["dedupe"] = $ord(self.dedupe.get())

  if url != "":
    data["url"] = url

  data["output_type"] = "2"

  if filepath != "":
    data.addFiles({"file": filepath})

  return data

proc search(self: SauceNao, url="", filepath=""): JsonNode =
  var data = self.processData(url, filepath)

  var client = newHttpClient()

  client.headers = newHttpHeaders({ "Content-Type": "application/json" })

  let response = client.post(sauceNaoUrl, multipart = data)
  var o = %response.body
  result = o

proc asyncSearch(self: SauceNao, url="", filepath=""): Future[JsonNode] {.async.} =
  var data = self.processData(url, filepath)

  var client = newAsyncHttpClient()

  client.headers = newHttpHeaders({ "Content-Type": "application/json" })

  let response = client.post(sauceNaoUrl, multipart = data)
  echo response.repr
  #var o = %response.body
  #result = o


proc fromFile*(self: SauceNao, filepath: string): JsonNode =
  result = self.search(filepath=filepath)

proc fromUrl*(self: SauceNao, url: string): JsonNode =
  result = self.search(url=url)

proc asyncFromFile*(self: SauceNao, filepath: string): Future[JsonNode] {.async.} =
  var o = await self.asyncSearch(filepath=filepath)
  result = o

proc asyncFromUrl*(self: SauceNao, url: string): Future[JsonNode] {.async.} =
  var o = await self.asyncSearch(url=url)
  result = o
