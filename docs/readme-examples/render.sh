#!/usr/bin/env bash
# Renders every ```typ block of README.md that produces output (blocks with only
# an import are skipped) to docs/readme-examples/NN.png, in order, on a white
# background trimmed to the ink plus an 8pt border (needs Typst and
# ImageMagick). Prints the <img> tag for each one: the width is half the pixel
# width, so the pictures show at text size and stay sharp on HiDPI screens.
set -u
cd "$(dirname "$0")/../.."
out=docs/readme-examples
tmp=$(mktemp -d .readme-examples.XXXXXX)
trap 'rm -rf "$tmp"' EXIT
rm -f "$out"/*.png
awk -v dir="$tmp" '
  /^```typ$/ { inside = 1; body = ""; real = 0; next }
  /^```$/ && inside {
    inside = 0
    if (real) {
      n++
      file = sprintf("%s/%02d.typ", dir, n)
      print "#import \"/nicematrix.typ\": *" > file
      print "#set page(width: auto, height: auto, margin: 16pt, fill: white)" > file
      print "#set text(size: 12pt)" > file
      printf "%s", body > file
      close(file)
    }
    next
  }
  inside {
    if ($0 ~ /^#import "@preview\//) next
    if ($0 !~ /^[[:space:]]*$/) real = 1
    body = body $0 "\n"
  }
' README.md
status=0
for f in "$tmp"/*.typ; do
  name=$(basename "$f" .typ)
  if typst compile --root . --ppi 192 "$f" "$out/$name.png" 2>"$tmp/$name.log"; then
    # 8pt at 192 ppi is 21 px.
    magick "$out/$name.png" -trim +repage -bordercolor white -border 21 "$out/$name.png"
    width=$(( $(identify -format '%w' "$out/$name.png") / 2 ))
    echo "<img src=\"$out/$name.png\" width=\"$width\" alt=\"\">"
  else
    echo "FAIL $name"; sed 's/^/     /' "$tmp/$name.log"; status=1
  fi
done
exit $status
