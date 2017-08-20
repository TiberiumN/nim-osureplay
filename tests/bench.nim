import nimbench, ../src/osureplay


let data = readFile("tests/resources/freedomdive.osr")

bench("Replays per second (freedomdive.osr)", m):
  for x in 1..m:
    var r = parseReplay(data)
    doNotOptimizeAway(r)

runBenchmarks()