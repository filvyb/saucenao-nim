import std/options

import enums

let sauceNaoUrl = "https://saucenao.com/search.php"

type
  SauceNao = object of RootObj
    key: Option[string]
    testmode: int
    dbmask: Option[int]
    db: DBs
    dbs: Option[seq[DBs]]
    numres: int
    dedupe: Option[Dedupe]
    hide: Option[Hide]

proc initSauceNao(key: string): SauceNao =
  result.key = some key
