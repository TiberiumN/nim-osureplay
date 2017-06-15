[![Build Status](https://travis-ci.org/TiberiumN/nim-osureplay.svg?branch=master)](https://travis-ci.org/TiberiumN/nim-osureplay)
# osureplay, a parser for osu replays in Nim

This is a parser for osu! rhythm game replays as described by https://osu.ppy.sh/wiki/Osr_(file_format)
Originally this parser was ported from [this](https://github.com/kszlim/osu-replay-parser) Python replay parser

## Installation
To install osrparse, simply:
```
$ nimble install osureplay
```

## Documentation
To parse a replay from a filepath:
```nim
import osureplay

let replay = parseReplayFile("replay.osr")
```

To parse a replay from a string which contains replay data:
```nim
import osureplay

let replay = parseReplay(data)
```

Replay objects provide these fields
```nim
replay.gameMode # GameMode enum
replay.gameVersion # Integer
replay.beatmapHash # String
replay.playerName # String
replay.replayHash # String
replay.number300s # Integer
replay.number100s # Integer
replay.number50s # Integer
replay.gekis # Integer
replay.katus # Integer
replay.misses # Integer
replay.score # Integer
replay.maxCombo # Integer
replay.isPerfectCombo # Boolean
replay.mods # set of Mods
replay.lifeBarGraph # String, unparsed as of now
replay.timestamp # TimeInfo object
replay.playData # Sequence of ReplayEvent tuples
```

ReplayEvent tuples provide these fields
```nim
event.timeSincePreviousAction #Integer representing time in milliseconds
event.x # X axis location
event.y # Y axis location
event.keysPressed # Bitwise sum of keys pressed, documented in OSR format page.
```
