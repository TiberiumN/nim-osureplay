import osureplay, os, strutils, times

if paramCount() < 1:
  echo "Usage - osureader filename.osr"
  quit()

let r = parseReplayFile(paramStr(1))
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
          r.number50s, r.gekis, r.katus, r.misses, r.score, 
          r.maxCombo, r.isPerfectCombo,r.mods, len(r.playEvents))