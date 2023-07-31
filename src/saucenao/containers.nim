import std/json
import std/strutils

type
  SauceHeader* = object
  Sauce* = object
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

proc initNaoResponse*(raw: JsonNode): NaoResponse =
  var header = raw{"header"}
  result.raw = raw
  result.user_id = header{"user_id"}.getStr("-6")
  result.account_type = parseInt(header{"account_type"}.getStr("-1"))
  result.short_limit = parseInt(header{"short_limit"}.getStr("-4"))
  result.long_limit = parseInt(header{"long_limit"}.getStr("-100"))
  result.short_remaining = header{"short_remaining"}.getInt(-4)
  result.long_remaining = header{"long_remaining"}.getInt(-100)
  result.status = header{"status"}.getInt(-100)
  result.results_requested = header{"results_requested"}.getInt(-16)
  result.search_depth = parseInt(header{"search_depth"}.getStr("-128"))
  result.minimum_similarity = header{"minimum_similarity"}.getFloat(-1.0)
  result.results_returned = header{"results_returned"}.getInt(-16)

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
