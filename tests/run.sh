#!/usr/bin/env bash
# Compiles every test document; assertions inside the documents fail the run.
set -u
cd "$(dirname "$0")/.."
mkdir -p tests/out
status=0
for f in tests/*.typ; do
  name=$(basename "$f" .typ)
  if typst compile --root . "$f" "tests/out/$name-{p}.png" --ppi 144 2>"tests/out/$name.log"; then
    echo "ok   $name"
  else
    echo "FAIL $name"; sed 's/^/     /' "tests/out/$name.log"; status=1
  fi
done
exit $status
