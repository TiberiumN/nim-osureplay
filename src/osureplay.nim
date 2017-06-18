import os, times, strutils, lzma, strscans
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
  
  Button* {.pure.} = enum
    M1 = 2, M2 = 4, K1 = 32, K2 = 1024

  ReplayEvent* = tuple[
    timeSincePreviousAction: int,  # in ms
    x, y: float,
    keysPressed: int,  # bitwise combination of keys pressed
    timestamp: int  # Absolute timestamp in ms (from replay start)
  ]
  
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
    playEvents*: seq[ReplayEvent]

proc `$`*(mode: GameMode): string = 
  case mode
  of gmStandart:
    "osu!standart"
  of gmTaiko:
    "osu!taiko"
  of gmCatchTheBeat:
    "osu!ctb"
  of gmMania:
    "osu!mania"

proc readUleb128(r: var Replay): int {.inline.} = 
  ## Converts ULEB128 to int
  result = 0
  var shift = 0
  while true:
    let byt = byte(r.raw[r.offset])
    inc r.offset
    result = result or ((byt and 0b01111111) shl shift)
    if (byt and 0b10000000) == 0x00:
      break
    shift += 7
  
proc parseString(r: var Replay): string {.inline.} =
  # Get int value of char at current pos
  case ord(r.raw[r.offset])
  of 0x00:
    # Return empty string
    inc r.offset
    result = ""
  of 0x0b:
    # String length and string itself
    inc r.offset
    let 
      stringLength = r.readUleb128()
      offsetEnd = r.offset + stringLength
    result = r.raw[r.offset..offsetEnd-1]
    r.offset = offsetEnd
  else:
    raise newException(ValueError, "Invalid replay!")

proc readByte(r: var Replay): byte {.inline.} = 
  result = byte(r.raw[r.offset])
  inc r.offset

proc readBool(r: var Replay): bool {.inline.} = 
  return bool(r.readByte())

proc readShort(r: var Replay): int16 {.inline.} = 
  let b1 = r.readByte()
  let b2 = r.readByte()
  result = b1.int16 + b2.int16 shl 8

proc readInt(r: var Replay): int {.inline.} = 
  #let bytes = r.raw[r.offset..r.offset+3]
  #r.offset += 4
  #echo cast[int](bytes)
  let b1 = r.readByte()
  let b2 = r.readByte()
  let b3 = r.readByte()
  let b4 = r.readByte()
  result = b1.int32 + b2.int32 shl 8 + b3.int32 shl 16 + b4.int32 shl 24

proc readInt64(r: var Replay): int64 {.inline.} = 
  let bytes = r.raw[r.offset..^r.offset+7]
  r.offset += 8
  for i in 0..sizeof(int64)-1:
    result = result shl 8
    result = result or bytes[8 - i - 1].int64
  
proc parseReplay*(raw: string): Replay =
  ## Parses replay by raw data from $raw and returns Replay object
  result.raw = raw
  result.gameMode = GameMode(result.readByte())
  result.gameVersion = result.readInt()
  result.beatmapHash = result.parseString()
  result.playerName = result.parseString()
  result.replayHash = result.parseString()
  result.number300s = result.readShort()
  result.number100s = result.readShort()
  result.number50s = result.readShort()
  result.gekis = result.readShort() # special 300's
  result.katus = result.readShort() # special 100's
  result.misses = result.readShort()
  result.score = result.readInt()
  result.maxCombo = result.readShort()
  # True - no misses and no slider breaks and no early finished sliders
  result.isPerfectCombo = result.readBool()
  result.mods = cast[set[Mod]](result.readInt())
  result.lifeBarGraph = result.parseString()

  let 
    data = result.readInt64()
    # Convert C# DateTime Ticks to Unix Timestamp
    unixTimestamp = int float(data - 621355968000000000) / 10000000
  result.timestamp = getGMTime(fromSeconds(unixTimestamp))
  result.replayLength = result.readInt()

  result.playEvents = @[]
  # No play data parsing for another game modes yet :(
  if result.gameMode != gmStandart: return result
  let offsetEnd = result.offset + result.replayLength
  # Decompress LZMA-compressed string and split it by ","
  let rawPlayData = decompress(result.raw[result.offset..offsetEnd-1]).split(",")
  # Use less reallocations by preallocating a sequence 
  # (because we know the length of a resulting sequence)
  # len-1 because last entry would be empty (because of extra "," at the end)
  result.playEvents = newSeq[ReplayEvent](len(rawPlayData)-1)
  var timestamp = 0  # absolute timestamp
  for index, rawEvent in rawPlayData:
    var 
      time, keys: int
      x, y: float
    # scanf from strscans is faster than splitting by |
    if scanf(rawEvent, "$i|$f|$f|$i", time, x, y, keys):
      timestamp += time
      result.playEvents[index] = (time, x, y, keys, timestamp)

proc parseReplayFile*(filepath: string): Replay = 
  ## Parses replay file in $filepath and returns Replay object
  return parseReplay(readFile(filepath))