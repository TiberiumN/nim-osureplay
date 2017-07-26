# Package
version     = "0.0.3"
author      = "Daniil Yarancev"
description = "Osu replay parser library and command-line utility."
license     = "MIT"
srcDir      = "src"
bin = @["osureader"]
requires "nim >= 0.16.0"

task test, "Runs the test suite":
  exec "nim c -r tests/tester"