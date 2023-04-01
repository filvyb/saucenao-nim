import std/options
import std/json
import std/httpclient
import std/asyncdispatch
import std/streams

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


proc search(self: SauceNao, url="", filepath=""): JsonNode =
  if url != "" and filepath != "":
    raise newException(UrlAndFileError, "Can't search for file and URL at the same time")
  
  var params = newJObject()
  if self.key.isSome:
    params["api_key"] = newJString(self.key.get())
  if self.dbmask.isSome:
    params["dbmask"] = newJInt(self.dbmask.get())
  if self.dbmaski.isSome:
    params["dbmaski"] = newJInt(self.dbmaski.get())

  var tmpseq: seq[int]
  for d in self.dbs:
    tmpseq &= ord(d)
  #params["dbs"] = %tmpseq
  params["db"] = newJInt(999)
  params["numres"] = newJInt(self.numres)

  if self.dedupe.isSome:
    params["dedupe"] = newJInt(ord(self.dedupe.get()))

  if url != "":
    params["url"] = newJString(url)

  params["output_type"] = newJInt(2)

  echo $params

  var client = newHttpClient()

  client.headers = newHttpHeaders({ "Content-Type": "application/json" })

  var data = newMultipartData()
  if filepath != "":
    data.addFiles({"uploaded_file": filepath})

  let response = client.request(sauceNaoUrl, httpMethod = HttpPost, body = $params, multipart = data)
  var o = readAll(response.bodyStream)
  result = %o


proc from_file*(self: SauceNao, filepath: string): JsonNode =
  result = self.search(filepath=filepath)

proc from_url*(self: SauceNao, url: string): JsonNode =
  result = self.search(url=url)
