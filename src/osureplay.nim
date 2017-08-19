import os, times, strutils, lzma, strscans, streams, parseutils
# Export times module (for timestamp)
export times

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

proc readUleb128(r: var Replay, stream: StringStream): int {.inline.} = 
  ## Converts ULEB128 to int
  var 
    shift = 0
    b: int8
  if shift == 5 * 7:
    raise newException(ValueError, "Wrong uleb!")
  b = stream.readInt8()
  result = result or ((b and 0x7F) shl shift)
  shift += 7
  while (b and 0x80) != 0:
    if shift == 5 * 7:
      raise newException(ValueError, "Wrong uleb!")
    b = stream.readInt8()
    result = result or ((b and 0x7F) shl shift)
    shift += 7

proc parseString(r: var Replay, stream: StringStream): string {.inline.} =
  # Get int value of char at current pos
  if stream.readInt8() != 0x0B:
    return ""
  # Read string with length 
  result = stream.readStr(r.readUleb128(stream))

proc parseReplay*(raw: string): Replay =
  ## Parses replay by raw data from $raw and returns Replay object
  # Create new string stream (for reading binary data)
  let raw = newStringStream(raw)
  result.gameMode = GameMode(raw.readInt8())
  result.gameVersion = raw.readInt32()
  result.beatmapHash = result.parseString(raw)
  result.playerName = result.parseString(raw)
  result.replayHash = result.parseString(raw)
  result.number300s = raw.readInt16()
  result.number100s = raw.readInt16()
  result.number50s = raw.readInt16()
  result.gekis = raw.readInt16() # special 300's
  result.katus = raw.readInt16() # special 100's
  result.misses = raw.readInt16()
  result.score = raw.readInt32()
  result.maxCombo = raw.readInt16()
  # True - no misses and no slider breaks and no early finished sliders
  result.isPerfectCombo = raw.readBool()
  result.mods = cast[set[Mod]](raw.readInt32())
  result.lifeBarGraph = result.parseString(raw)
  # Convert C# DateTime Ticks to Unix Timestamp
  let unixTimestamp = float(raw.readInt64() - 621355968000000000) / 10000000
  result.timestamp = getGMTime(fromSeconds(unixTimestamp))
  let replayLength = raw.readInt32()

  # No play data parsing for another game modes yet :(
  if result.gameMode != gmStandart: return result
  # Decompress LZMA-compressed string
  let rawPlayData = decompress(raw.readStr(replayLength))
  
  # Use less reallocations by preallocating a sequence of events
  # -1 because there is , at the end of play events string
  result.playEvents = newSeq[ReplayEvent](rawPlayData.count(',')-1)
  var 
    timestamp = 0  # Absolute timestamp
    token: string  # Current play event string
    time: int  # Time since last event 
    keys: int # Bitmask of pressed keys
    x, y: float  # X and Y positions
    curPos = rawPlayData.parseUntil(token, ",", 0)
    i = 0  # Current index
  # It's faster to use parseUntil instead of split
  while true:
    let processed = rawPlayData.parseUntil(token, ',', curPos+1)
    # If there's no play events left
    if processed == 0: 
      break
    # Add processed chars to current position + 1 char to skip ,
    curPos += processed + 1
    # scanf from strscans is than splitting by |
    if scanf(token, "$i|$f|$f|$i", time, x, y, keys):
      timestamp += time
      result.playEvents[i] = (time, x, y, keys, timestamp)
    inc i
  # Close stream
  raw.close()

proc parseReplayFile*(filepath: string): Replay = 
  ## Parses replay file in $filepath and returns Replay object
  return parseReplay(readFile(filepath))