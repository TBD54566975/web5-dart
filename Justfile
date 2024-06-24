_help:
  @just -l

get:
  #!/bin/bash
  set -euo pipefail

  echo "Getting dependencies for packages"
  dart pub get

test:
  #!/bin/bash
  set -euo pipefail

  git submodule init
  git submodule update
  dart test

analyze:
  #!/bin/bash
  set -euo pipefail

  dart analyze
