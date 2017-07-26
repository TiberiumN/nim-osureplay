import osureplay, unittest, times

suite "Standart osu! game mode replays parsing":
  let cookiezi = parseReplayFile("tests/resources/cookiezi817.osr")

  test "Game mode":
    check(cookiezi.gameMode == gmStandart)

  test "Game version":
    check(cookiezi.gameVersion == 20151228)

  test "Beatmap hash":
    check(cookiezi.beatmapHash == "d7e1002824cb188bf318326aa109469d")

  test "Player name":
    check(cookiezi.playerName == "Cookiezi")

  test "Number of hits (300s, 100s, 50s, etc)":
    check(cookiezi.number300s == 1165)
    check(cookiezi.number100s == 8)
    check(cookiezi.number50s == 0)
    check(cookiezi.gekis == 254)
    check(cookiezi.katus == 7)
    check(cookiezi.misses == 0)
  
  test "Score":
    check(cookiezi.score == 72389038)

  test "Max combo":
    check(cookiezi.maxCombo == 1773)

  test "Is it a perfect combo":
    check(cookiezi.isPerfectCombo == false)

  test "Mod combinations":
    check(cookiezi.mods == {Mod.Hidden, Mod.DoubleTime})

  test "Timestamp":
    check($cookiezi.timestamp == "2016-01-02T23:52:27+00:00")

  test "Play data":
    check(cookiezi.playEvents[0] is ReplayEvent)
    check(len(cookiezi.playEvents) == 16160)