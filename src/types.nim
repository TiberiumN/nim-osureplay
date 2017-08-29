type
  GameMode* = enum gmStandard, gmTaiko, gmCatchTheBeat, gmMania

proc `$`*(mode: GameMode): string = 
  case mode
  of gmStandard: "osu!standard"
  of gmTaiko: "osu!taiko"
  of gmCatchTheBeat: "osu!ctb"
  of gmMania: "osu!mania"