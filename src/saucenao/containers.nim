import std/json
import std/strutils
import std/options
import std/times

import enums

type
  Sauce* = object
    raw*: JsonNode
    similarity*: float
    thumbnail*: string
    urls*: seq[string]
    title*: Option[string]
    author*: Option[string]
    index_name*: string
    case index_id*: DBs
    of HMagazines, Madokami, MangaDex:
      md_id*: Option[string]
      mu_id*: Option[string]
      manga_mal_id*: Option[string]
      part*: string
      date*: Option[string]
      mado_type*: Option[string]
    of HGame_CG:
      getchu_id*: string
    of Pixiv_Images, Pixiv_History:
      pixiv_id*: string
      pixiv_member_id*: string
    of Nico_Nico_Seiga:
      seiga_id*: string
      seiga_member_id*: string
    of Danbooru, Gelbooru, Yandere, Konachan, SankakuChannel, AnimePicturesnet, E621net, IdolComplex:
      booru_id*: string
      material*: Option[seq[string]]
      characters*: Option[seq[string]]
    of Drawr_Images:
      drawr_id*: string
      drawr_member_id*: string
    of Nijie_Images:
      nijie_id*: string
      nijie_member_id*: string
    of Fakku, HMisc_NHentai, TwoDMarket, HMisc_EHentai:
      source*: string
    of MediBang:
      medi_member_id*: string
    of Anime, HAnime, Movies, Shows:
      anidb_aid*: Option[string]
      mal_id*: Option[string]
      anilist_id*: Option[string]
      imdb_id*: Option[string]
      episode*: Option[string]
      year*: string
      est_time*: string
    of Bcynet_Illust, Bcynet_Cosplay:
      bcy_id*: string
      bcy_member_id*: string
      bcy_member_link_id*: string
      bcy_type*: string
    of PortalGraphicsnet:
      pg_id*: string
      pg_member_id*: string
    of DeviantArt:
      da_id*: string
    of Pawoo:
      created_at*: DateTime
      pawoo_id*: string
    of Artstation:
      as_project*: string
    of FurAffinity:
      fa_id*: string
    of Twitter:
      created_at_tw*: DateTime
      tweet_id*: string
      twitter_user_id*: string
    of Furry_Network:
      fn_id*: string
      fn_type*: string
    of Kemono:
      published*: DateTime
      service*: string
      service_name*: string
      kemono_id*: string
      kemono_user_id*: string
    of Skeb:
      path*: string

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
  elif data.hasKey("user_name"):
    result = some data["user_name"].getStr()
    
proc parseResults(res: JsonNode): seq[Sauce] =
  for i in res.getElems():
    var header = i["header"]
    var data = i["data"]
    #echo header
    var index_id = header["index_id"].getInt()
    var index_name = header["index_name"].getStr()
    #saucenao bug workaround
    if index_id > 44 or index_id < 0:
      var ts = index_name.find("#")+1
      var te = index_name.find(":")
      #echo index_name[ts ..< te]
      index_id = parseInt(index_name[ts ..< te])
    var sauce = Sauce(index_id: DBs(index_id))

    sauce.raw = res
    sauce.similarity = header["similarity"].getFloat()
    sauce.thumbnail = header["thumbnail"].getStr()
    #sauce.index_id = DBs(header["index_id"].getInt())
    sauce.index_name = index_name

    if data.hasKey("ext_urls"):
      for u in data["ext_urls"].getElems():
        sauce.urls.add(u.getStr(""))
    elif data.hasKey("getchu_id"):
      for u in data["getchu_id"].getElems():
        sauce.urls.add("http://www.getchu.com/soft.phtml?id=" & u.getStr(""))

    sauce.title = getTitle(data)
    sauce.author = getAuthor(data)

    case sauce.index_id
      of DBs.HMagazines:
        sauce.part = data["part"].getStr()
        sauce.date = some data["date"].getStr()
      of DBs.HGame_CG:
        sauce.getchu_id = data["getchu_id"].getStr()
      of DBs.Pixiv_Images, DBs.Pixiv_History:
        sauce.pixiv_id = $data["pixiv_id"].getInt()
        sauce.pixiv_member_id = $data["member_id"].getInt()
      of DBs.Nico_Nico_Seiga:
        sauce.seiga_id = $data["seiga_id"].getInt()
        sauce.seiga_member_id = $data["member_id"].getInt()
      of DBs.Drawr_Images:
        sauce.drawr_id = $data["drawr_id"].getInt()
        sauce.drawr_member_id = $data["member_id"].getInt()
      of DBs.Nijie_Images:
        sauce.nijie_id = $data["nijie_id"].getInt()
        sauce.nijie_member_id = $data["member_id"].getInt()
      of DBs.MediBang:
        sauce.medi_member_id = $data["member_id"].getInt()
      of DBs.Anime, DBs.HAnime, DBs.Movies, DBs.Shows:
        if data.hasKey("anidb_aid"):
          sauce.anidb_aid = some $data["anidb_aid"].getInt()
        if data.hasKey("mal_id"):
          sauce.mal_id = some $data["mal_id"].getInt()
        if data.hasKey("anilist_id"):
          sauce.anilist_id = some $data["anilist_id"].getInt()
        if data.hasKey("imdb_id"):
          sauce.imdb_id = some data["imdb_id"].getStr()
        if data["part"].getStr("") != "":
          sauce.episode = some data["part"].getStr()
        sauce.year = data["year"].getStr()
        sauce.est_time = data["est_time"].getStr()
      of DBs.Danbooru, DBs.Gelbooru, DBs.Yandere, DBs.Konachan, DBs.SankakuChannel, DBs.AnimePicturesnet, DBs.E621net, DBs.IdolComplex:
        if data.hasKey("danbooru_id"):
          sauce.booru_id = $data["danbooru_id"].getInt()
        elif data.hasKey("yandere_id"):
          sauce.booru_id = $data["yandere_id"].getInt()
        elif data.hasKey("gelbooru_id"):
          sauce.booru_id = $data["gelbooru_id"].getInt()
        elif data.hasKey("konachan_id"):
          sauce.booru_id = $data["konachan_id"].getInt()
        elif data.hasKey("sankaku_id"):
          sauce.booru_id = $data["sankaku_id"].getInt()
        elif data.hasKey("anime-pictures_id"):
          sauce.booru_id = $data["anime-pictures_id"].getInt()
        elif data.hasKey("e621_id"):
          sauce.booru_id = $data["e621_id"].getInt()
        elif data.hasKey("idol_id"):
          sauce.booru_id = $data["idol_id"].getInt()
        if data["material"].getStr() != "":
          sauce.material = some data["material"].getStr().split(", ")
        if data["characters"].getStr() != "":
          sauce.material = some data["characters"].getStr().split(", ")        
      of DBs.Bcynet_Illust ,DBs.Bcynet_Cosplay:
        sauce.bcy_id = $data["bcy_id"].getInt()
        sauce.bcy_member_id = $data["member_id"].getInt()
        sauce.bcy_member_link_id = $data["member_link_id"].getInt()
        sauce.bcy_type = data["bcy_type"].getStr()
      of DBs.PortalGraphicsnet:
        sauce.pg_id = $data["pg_id"].getInt()
        sauce.pg_member_id = $data["member_id"].getInt()
      of DBs.DeviantArt:
        sauce.da_id = data["da_id"].getStr()
      of DBs.Pawoo:
        sauce.created_at = parse(data["created_at"].getStr(), "yyyy-MM-dd'T'hh:mm:ss'.'fffzzz", utc())
        sauce.pawoo_id = data["pawoo_id"].getStr()
      of DBs.Madokami:
        sauce.mu_id = some $data["mu_id"].getInt()
        sauce.part = data["part"].getStr()
        if data.hasKey("type"):
          sauce.mado_type = some data["type"].getStr()
      of DBs.MangaDex:
        if data.hasKey("md_id"):
          sauce.md_id = some data["md_id"].getStr()
        if data.hasKey("mu_id"):
          sauce.mu_id = some $data["mu_id"].getInt()
        if data.hasKey("mal_id"):
          sauce.manga_mal_id = some $data["mal_id"].getInt()
        sauce.part = data["part"].getStr()
      of DBs.Fakku, DBs.HMisc_NHentai, DBs.TwoDMarket, DBs.HMisc_EHentai:
        sauce.source = data["source"].getStr()
      of DBs.Artstation:
        sauce.as_project = data["as_project"].getStr()
      of DBs.FurAffinity:
        sauce.fa_id = $data["fa_id"].getInt()
      of DBs.Twitter:
        sauce.created_at_tw = parse(data["created_at"].getStr(), "yyyy-MM-dd'T'hh:mm:ss'Z'", utc())
        sauce.tweet_id = data["tweet_id"].getStr()
        sauce.twitter_user_id = data["twitter_user_id"].getStr()
      of DBs.Furry_Network:
        sauce.fn_id = $data["fn_id"].getInt()
        sauce.fn_type = data["fn_type"].getStr()
      of DBs.Kemono:
        sauce.published = parse(data["published"].getStr(), "yyyy-MM-dd'T'hh:mm:ss'.'fffzzz", utc())
        sauce.service = data["service"].getStr()
        sauce.service_name = data["service_name"].getStr()
        sauce.kemono_id = data["id"].getStr()
        sauce.kemono_user_id = data["user_id"].getStr()
      of DBs.Skeb:
        sauce.path = data["path"].getStr()

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
  #try:
  result.results = parseResults(raw["results"])
  #except CatchableError as e:
  #  echo e.msg
  #  echo raw["results"]

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
