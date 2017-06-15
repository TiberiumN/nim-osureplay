import os, struct, times, strutils, lzma, strscans
type
  GameMode* = enum gmStandart, gmTaiko, gmCatchTheBeat, gmMania
  Mod* {.pure.} = enum
    NoMod  # Only as a placeholder, check for empty set instead of this
    NoFail
    Easy
    # NoVideo - not a mod anymore
    Hidden
    HardRock
    SuddenDeath
    DoubleTime
    Relax
    HalfTime
    Nightcore  # Always used with DT: 512 + 64 = 576
    Flashlight
    Autoplay
    SpunOut
    Autopilot
    Perfect
    Key4
    Key5
    Key6
    Key7
    Key8
    keyMod  # Key4 + Key5 + Key6 + Key7 + Key8
    FadeIn
    Random
    LastMod  # Cinema
    FreeModAllowed  # osu!cuttingedge only
    Key9
    Coop
    Key1
    Key3
    Key2
    ScoreV2 # New, not documented in API yet
  
  ReplayEvent* = tuple[timeSincePreviousAction: int, x, y: float,
                       keysPressed: int]
  
  Replay* = object
    offset: int
    gameMode*: GameMode
    gameVersion*: int
    beatmapHash*, playerName*, replayHash*: string
    number300s*, number100s*, number50s*: int
    gekis*, katus*, misses*, score*: int
    maxCombo*: int
    isPerfectCombo*: bool
    mods*: set[Mod]
    lifeBarGraph*: string
    timestamp*: TimeInfo
    replayLength: int
    raw: string  # Raw replay data, only needed for parsing
    playData*: seq[ReplayEvent]

proc toMods(modNum: cint): set[Mod] {.inline.} =
  ## Converts modNum to set of mods
  # maybe we can get rid of this check?
  return cast[set[Mod]](modNum)

proc decodeInt(r: var Replay): int {.inline.} = 
  # ULEB128
  result = 0
  var shift = 0
  while true:
    let byt = ord(r.raw[r.offset])
    inc r.offset
    result = result or ((byt and 0b01111111) shl shift)
    if (byt and 0b10000000) == 0x00:
      break
    shift += 7
  
proc parseString(r: var Replay): string {.inline.} =
  # Get int value of char at current pos
  case ord(r.raw[r.offset])
  of 0x00:
    # Empty string
    inc r.offset
    result = ""
  of 0x0b:
    # String length and string itself
    inc r.offset
    let 
      stringLength = r.decodeInt()
      offsetEnd = r.offset + stringLength
    result = r.raw[r.offset..offsetEnd-1]
    r.offset = offsetEnd
  else:
    raise newException(ValueError, "Invalid replay!")

proc parseReplay*(raw: string): Replay =
  ## Parses replay by raw data from $raw and returns Replay object
  result.raw = raw
  block parseGameModeAndVersion:
    const 
      DataFormat = "<bi"
      DataLength = struct.calcsize(DataFormat)
    let data = struct.unpack(DataFormat, result.raw)
    result.offset += DataLength
    # Convert byte to value of GameMode enum
    result.gameMode = cast[GameMode](data[0].getByte) 
    result.gameVersion = data[1].getInt
  
  block parseBeatmapHash:
    result.beatmapHash = result.parseString()
  
  block parsePlayerName:
    result.playerName = result.parseString()
  
  block parseReplayHash:
    result.replayHash = result.parseString()
  
  block parseScoreStats:
    const
      DataFormat = "<hhhhhhih?i"
      DataLength = struct.calcsize(DataFormat)
    let data = struct.unpack(DataFormat, result.raw[result.offset..^1])
    result.offset += DataLength
    result.number300s = data[0].getInt
    result.number100s = data[1].getInt
    result.number50s = data[2].getInt
    result.gekis = data[3].getInt # special 300's
    result.katus = data[4].getInt # special 100's
    result.misses = data[5].getInt
    result.score = data[6].getInt
    result.maxCombo = data[7].getInt
    # True - no misses and no slider breaks and no early finished sliders
    result.isPerfectCombo = data[8].getBool
    result.mods = data[9].getInt.toMods()
  
  block parseLifeBarGraph:
    result.lifeBarGraph = result.parseString()
  
  block parseTimestampAndReplayLength:
    const
      DataFormat = "<qi"
      DataLength = struct.calcsize(DataFormat)
    let 
      data = struct.unpack(DataFormat, result.raw[result.offset..^1])
      # Convert C# DateTime Ticks to Unix Timestamp
      unixTimestamp = int float(data[0].getQuad - 621355968000000000) / 10000000
    result.timestamp = getGMTime(fromSeconds(unixTimestamp))
    result.replayLength = data[1].getInt
    result.offset += DataLength
  
  block parseReplayData:
    result.playData = @[]
    # No play data parsing for another game modes yet :(
    if result.gameMode != gmStandart: return result

    let offsetEnd = result.offset + result.replayLength
    # Decompress LZMA-compressed string and split it by ","
    let rawPlayData = decompress(result.raw[result.offset..offsetEnd-1]).split(",")
    # Use less reallocations by preallocating a sequence 
    # (because we know the length of a resulting sequence)
    # len-1 because last entry would be empty (because of extra "," at the end)
    result.playData = newSeq[ReplayEvent](len(rawPlayData)-1)
    for index, rawEvent in rawPlayData:
      var 
        time, keys: int
        x, y: float
      # scanf from strscans is faster than splitting by |
      if scanf(rawEvent, "$i|$f|$f|$i", time, x, y, keys):
        result.playData[index] = (time, x, y, keys)
  
proc parseReplayFile*(filepath: string): Replay = 
  ## Parses replay file in $filepath and returns Replay object
  return parseReplay(readFile(filepath))

when isMainModule:
  if paramCount() < 1:
    echo "Usage - osureplay.exe filename.osr"
    quit()
  let filename = paramStr(1)
  let r = parseReplayFile(filename)
  echo """Played by $1 at $2
Game Mode is $3
Game Version is $4
Beatmap hash - $5, replay hash - $6
Number of 300's - $7, 100's - $8, 50's - $9
Number of gekis - $10, katus - $11
Number of misses - $12
Total score - $13
Max combo - $14
Is it a perfect combo? $15 (no misses and no slider breaks and no early finished sliders)
Mods used - $16
Number of play data events - $17
""".format(r.playerName, r.timestamp, r.gameMode, r.gameVersion, 
            r.beatmapHash, r.replayHash, r.number300s, r.number100s, 
            r.number50s, r.gekis, r.katus, r.misses,r.score, 
            r.maxCombo, r.isPerfectCombo,r.mods, len(r.playData))
