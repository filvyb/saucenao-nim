import std/json
import std/strutils
import std/options

import enums

type
  Sauce* = object
    raw*: JsonNode
    similarity*: float
    thumbnail*: string
    index_id*: DBs
    index_name*: string
    urls*: seq[string]
    title*: Option[string]
    author*: Option[string]
  NaoResponse* = object
    raw*: JsonNode
    user_id*: string
    account_type*: int
    short_limit*: int
    long_limit*: int
    short_remaining*: int
    long_remaining*: int
    status*: int
    results_requested*: int
    search_depth*: int
    minimum_similarity*: float64
    results_returned*: int
    results*: seq[Sauce]

proc getTitle(data: JsonNode): Option[string] =
  if data.hasKey("title"):
    result = some data["title"].getStr()
  elif data.hasKey("eng_name"):
    result = some data["eng_name"].getStr()
  elif data.hasKey("material"):
    result = some data["material"].getStr()
  elif data.hasKey("source"):
    result = some data["source"].getStr()
  elif data.hasKey("created_at"):
    result = some data["created_at"].getStr()

proc getAuthor(data: JsonNode): Option[string] =
  if data.hasKey("author"):
    result = some data["author"].getStr()
  elif data.hasKey("author_name"):
    result = some data["author_name"].getStr()
  elif data.hasKey("member_name"):
    result = some data["member_name"].getStr()
  elif data.hasKey("pawoo_user_username"):
    result = some data["pawoo_user_username"].getStr()
  elif data.hasKey("twitter_user_handle"):
    result = some data["twitter_user_handle"].getStr()
  elif data.hasKey("company"):
    result = some data["company"].getStr()
  elif data.hasKey("creator"):
    if data["creator"].kind == JArray:
      result = some data["creator"].getElems()[0].getStr()
    else:
      result = some data["creator"].getStr()
    
proc parseResults(res: JsonNode): seq[Sauce] =
  for i in res.getElems():
    var header = i["header"]
    var data = i["data"]
    var sauce = Sauce()

    sauce.raw = res
    sauce.similarity = header["similarity"].getFloat()
    sauce.thumbnail = header["thumbnail"].getStr()
    sauce.index_id = DBs(header["index_id"].getInt())
    sauce.index_name = header["index_name"].getStr()

    if data.hasKey("ext_urls"):
      for u in data["ext_urls"].getElems():
        sauce.urls.add(u.getStr(""))
    elif data.hasKey("getchu_id"):
      for u in data["getchu_id"].getElems():
        sauce.urls.add("http://www.getchu.com/soft.phtml?id=" & u.getStr(""))

    sauce.title = getTitle(data)
    sauce.author = getAuthor(data)

    result.add(sauce)

proc initNaoResponse*(raw: JsonNode): NaoResponse =
  var header = raw["header"]
  result.raw = header
  result.user_id = header["user_id"].getStr("-6")
  result.account_type = parseInt(header["account_type"].getStr("-1"))
  result.short_limit = parseInt(header["short_limit"].getStr("-4"))
  result.long_limit = parseInt(header["long_limit"].getStr("-100"))
  result.short_remaining = header["short_remaining"].getInt(-4)
  result.long_remaining = header["long_remaining"].getInt(-100)
  result.status = header["status"].getInt(-100)
  result.results_requested = header["results_requested"].getInt(-16)
  result.search_depth = parseInt(header["search_depth"].getStr("-128"))
  result.minimum_similarity = header["minimum_similarity"].getFloat(-1.0)
  result.results_returned = header["results_returned"].getInt(-16)
  result.results = parseResults(raw["results"])

proc `$`*(ob: NaoResponse): string =
  result &= "("
  result &= "user_id: " & ob.user_id & ", "
  result &= "account_type: " & $ob.account_type & ", "
  result &= "short_limit: " & $ob.short_limit & ", "
  result &= "long_limit: " & $ob.user_id & ", "
  result &= "short_remaining: " & $ob.short_remaining & ", "
  result &= "long_remaining: " & $ob.long_remaining & ", "
  result &= "status: " & $ob.status & ", "
  result &= "results_requested: " & $ob.results_requested & ", "
  result &= "search_depth: " & $ob.search_depth & ", "
  result &= "minimum_similarity: " & $ob.minimum_similarity & ", "
  result &= "results_returned: " & $ob.results_returned & ", "
  result &= "results: " & $ob.results
  result &= ")"

proc `$`*(ob: Sauce): string =
  result &= "("
  result &= "similarity: " & $ob.similarity & ", "
  result &= "thumbnail: " & ob.thumbnail & ", "
  result &= "index_id: " & $ob.index_id & ", "
  result &= "index_name: " & ob.index_name & ", "
  result &= "urls: " & $ob.urls & ", "
  result &= "title: " & $ob.title & ", "
  result &= "author: " & $ob.author
  result &= ")"
