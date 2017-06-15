# Package
version     = "0.0.1"
author      = "Daniil Yarancev"
description = "Osu replay parser."
license     = "MIT"
srcDir      = "src"
bin = @["osureplay.exe"]
requires "nim >= 0.17.0"

task test, "Runs the test suite":
  exec "nim c -r tests/tester"