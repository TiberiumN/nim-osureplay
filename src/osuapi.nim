import httpclient, json, times, strutils, asyncdispatch
import types

type
  OsuApiBase[Client] = object
    kind: Client
    key: string
  
  ## Osu api object
  OsuApi* = OsuApiBase[HttpClient]
  
  ## Async osu api object
  AsyncOsuApi* = OsuApiBase[AsyncHttpClient]
  
  ## Approved state of the beatmap
  ApprovedState* = enum 
    asGraveyard = -2, asWip = -1, asPending = 0, asRanked = 1, 
    asApproved = 2, asQualified = 3, asLoved = 4

  ## Beatmap genre
  Genre* {.pure.} = enum
    Any = 0, Unspecified = 1, VideoGame = 2, Anime = 3, Rock = 4,
    Pop = 5, Other = 6, Novelty = 7, HipHop = 9, Electronic = 10
  
  ## Beatmap language
  Language* = enum
    langAny = 0, langOther = 1, langEnglish = 2, langJapanese = 3, 
    langChinese = 4, langInstrumental = 5, langKorean = 6, langFrench = 7,
    langGerman = 8, langSwedish = 9, langSpanish = 10, langItalian = 11
  
  ## Beatmap object (from API)
  ApiBeatmap* = object
    approvedState*: ApprovedState 
    approvedDate*: DateTime
    lastUpdate*: DateTime
    artist*: string
    id*: int
    setId*: int
    bpm*: float
    creator*: string
    diffRating*: float
    diffSize*: int
    diffOverall*: int
    diffApproach*: int
    diffDrain*: int
    hitLenght*: int
    source*: string
    genre*: Genre
    language*: Language
    title*: string
    totalLength*: int
    version*: string
    mode*: GameMode
    tags*: seq[string]
    favorCount*: int
    playCount*: int
    passCount*: int
    maxCombo*: int

const
  ApiUrl = "http://osu.ppy.sh/api/"

proc `$`*(state: ApprovedState): string = 
  case state
  of asGraveyard: "Graveyard"
  of asWip: "WIP"
  of asPending: "Pending"
  of asRanked: "Ranked"
  of asApproved: "Approved"
  of asQualified: "Qualified"
  of asLoved: "Loved"

proc `$`*(lang: Language): string = 
  case lang
  of langAny: "Any"
  of langOther: "Other"
  of langEnglish: "English"
  of langJapanese: "Japanese"
  of langChinese: "Chinese"
  of langInstrumental: "Instrumental"
  of langKorean: "Korean"
  of langFrench: "French"
  of langGerman: "German"
  of langSwedish: "Swedish"
  of langSpanish: "Spanish"
  of langItalian: "Italian"

proc newOsuApi*(key: string): auto = 
  ## Create new OsuApi object
  OsuApi(key: key)

proc newAsyncOsuApi*(key: string): auto = 
  ## Create new AsyncOsuApi object
  AsyncOsuApi(key: key)

proc getBeatmap*(data: string): ApiBeatmap = 
  ## Get beatmap from *data* and parse it to ApiBeatmap object
  let data = data.parseJson()[0]
  # For some UNKNOWN reason osu!api uses ONLY strings as field types
  # so we can't use json.to macro here :(
  result.approvedState = ApprovedState(data["approved"].str.parseInt)
  const dateFmt = "yyyy-MM-dd HH:mm:ss"
  result.approvedDate = times.parse(data["approved_date"].str, dateFmt)
  result.lastUpdate = times.parse(data["last_update"].str, dateFmt)
  result.artist = data["artist"].str
  result.id = data["beatmap_id"].str.parseInt
  result.setId = data["beatmapset_id"].str.parseInt
  result.bpm = data["bpm"].str.parseFloat
  result.creator = data["creator"].str
  result.diffRating = data["difficultyrating"].str.parseFloat
  result.diffSize = data["diff_size"].str.parseInt
  result.diffOverall = data["diff_overall"].str.parseInt
  result.diffApproach = data["diff_approach"].str.parseInt
  result.diffDrain = data["diff_drain"].str.parseInt
  result.hitLenght = data["hit_length"].str.parseInt
  result.source = data["source"].str
  result.genre = Genre(data["genre_id"].str.parseInt)
  result.language = Language(data["language_id"].str.parseInt)
  result.title = data["title"].str
  result.totalLength = data["total_length"].str.parseInt
  result.version = data["version"].str
  result.mode = GameMode(data["mode"].str.parseInt)
  result.tags = data["tags"].str.splitWhitespace()
  result.favorCount = data["favourite_count"].str.parseInt
  result.playCount = data["playcount"].str.parseInt
  result.passCount = data["passcount"].str.parseInt
  result.maxCombo = data["max_combo"].str.parseInt

proc getBeatmap*(api: OsuApi | AsyncOsuApi, hash: string): 
                Future[ApiBeatmap] {.multisync.} = 
  ## Get beatmap by *hash* and return ApiBeatmap object
  let c = when api is OsuApi: newHttpClient() else: newAsyncHttpClient()
  let url = (ApiUrl & "get_beatmaps?k=$1&h=$2" % [api.key, hash])
  result = getBeatmap(await c.getContent(url))