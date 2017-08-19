import nimbench, ../src/osureplay


let data = readFile("tests/resources/cookiezi817.osr")

bench("Replays per second (cookiezi817.osr)", m):
  for x in 1..m:
    var r = parseReplay(data)
    doNotOptimizeAway(r)

runBenchmarks()