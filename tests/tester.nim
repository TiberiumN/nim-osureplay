import osureplay, unittest, times

suite "Standart osu! game mode replays parsing":
  let replay = parseReplayFile("tests/resources/replay.osr")
  let combReplay = parseReplayFile("tests/resources/replay2.osr")

  test "Game mode":
    check(replay.gameMode == gmStandart)
    
  test "Game version":
    check(replay.gameVersion == 20140226)
    
  test "Beatmap hash":
    check(replay.beatmapHash == "da8aae79c8f3306b5d65ec951874a7fb")
  
  test "Player name":
    check(replay.playerName == "Cookiezi")
  
  test "Number of hits (300s, 100s, 50s, etc)":
    check(replay.number300s == 1982)
    check(replay.number100s == 1)
    check(replay.number50s == 0)
    check(replay.gekis == 250)
    check(replay.katus == 1)
    check(replay.misses == 0)
  
  test "Max combo":
    check(replay.maxCombo == 2385)
  
  test "Is it a perfect combo":
    check(replay.isPerfectCombo == true)
  
  test "Mod combination (replay with no mods)":
    check(replay.mods == {})
  
  test "Mod combination (replay with two mods)":
    check(combReplay.mods == {Mod.Hidden, Mod.HardRock})
  
  test "Timestamp":
    check($replay.timestamp == "2013-02-01T16:31:34+00:00")
    
  test "Play data":
    check(replay.playData[0] is ReplayEvent)
    check(len(replay.playData) == 17500)