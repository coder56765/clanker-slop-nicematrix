#import "../src/lib.typ": *
#set page(width: 16cm, height: auto, margin: 1cm)
#set text(size: 11pt)

#show: nicemat-setup

= Inline equations

Inline: $nicemat(1, 2; 3, 4)$ versus $mat(1, 2; 3, 4)$, and
$nicemat(a, dots.c, a; dots.v, dots.down, dots.v; a, dots.c, a)$ versus
$mat(a, dots.c, a; dots.v, dots.down, dots.v; a, dots.c, a)$ in a line of text.
Forced display size: $nicemat(1, 2; 3, 4, small: #false)$; nicematrix's small:
$nicemat(1, 2; 3, 4, small: #true)$.

$ nicemat(1, 2; 3, 4) quad mat(1, 2; 3, 4) quad nicemat(nicemat(1, 2; 3, 4), 0; 0, 1) quad mat(mat(1, 2; 3, 4), 0; 0, 1) $

= Multi-line cells

$ nicemat(delim: "[", hvlines: #true,
  cell(x + y \ = z, rowspan: #2), a, b;
  c, d;
  1, "first" \ "second", 3) $

$ nicearray(align: #left, vlines: 1, a \ b \ c, x; y, z) $

= Markers outside nicemat

$ mat(1, cdots(), 1; vdots(), ddots(), vdots(); 1, cdots(), 1) quad
  mat(cell(a, rowspan: #2), b; c, d) quad mat(diagbox(x, y), 1; 2, 3) $

= Shorthands

$ nicemat(hvlines: #true, borders: #false, a, b, c; d, e, f; g, h, i) quad
  nicemat(delim: #none, hvlines: #true, a, b; c, d) quad
  nicemat(hlines: #true, borders: #true, a, b; c, d) $

$ nicemat(
  1, 2, 3, 4; 5, 6, 7, 8; 9, 10, 11, 12;
  region(row: 1, fill: #yellow.lighten(60%), radius: #2pt),
  region(cols: (2, 3), stroke: #red),
  submatrix(rows: (0, 1), cols: (0, 1)),
  hbrace(A, cols: (0, 1)),
  vbrace(B, rows: (1, 2))) $

= Connect and bend

$ nicemat(column-gap: #2.5em, row-gap: #1.5em,
  a, b, c;
  d, e, f;
  connect((0, 0), (1, 2)),
  connect((1, 0), (0, 2), bend: 30, stroke: #blue),
  dotline((0, 1), (1, 1), bend: −40),
  connect((0, 0), (1, 0), bend: 45, above: n, marks: "<->")) $

$ nicearray(
  x, -oo, , 0, , +oo;
  f(x), , , 1, , ;
  f(x), +oo, , , , 0;
  connect((2, 1), (1, 3)),
  connect((1, 3), (2, 5), bend: −20)) $

= Debug

$ nicemat(first-row: #true, first-col: #true, debug: #true,
  , C_1, C_2, C_3; L_1, a, b, c; L_2, d, e, f) quad
  nicemat(debug: "rules", 1, 2; 3, 4) quad
  nicemat(debug: "cells", 1, 2; 3, 4) $

= Leader colours

$ nicemat(first-row: #true, last-col: #true,
  dots: #(fill: (i, j) => if i == 0 or j == 4 { blue } else { none }),
  map-cells: #((i, j, b) => if i == 0 or j == 4 { text(fill: blue, b) } else { b }),
  C_1, dots.c, , C_n, ;
  a_(1 1), dots.c, , a_(1 n), L_1;
  dots.v, , , dots.v, dots.v;
  a_(n 1), dots.c, , a_(n n), L_n) $

Small dots: $nicemat(1, dots.c, 1; dots.v, dots.down, dots.v; 1, dots.c, 1, small: #true)$
and $nicemat(1, dots.c, 1; dots.v, dots.down, dots.v; 1, dots.c, 1)$.

= Named matrices

$ A = nicemat(name: "A", 1, 2; 3, 4) wide B = nicemat(name: "B", a, b, c; d, e, f) $
#nicemat-connect(("A", (0, 1)), ("B", (0, 0)), bend: 30deg, above: $T$)
#nicemat-connect(("A", (1, 1)), ("B", (1, 2)), bend: -20deg, stroke: auto, marks: none)
#nicemat-connect(("B", (0, 2)), ("B", (1, 0)), stroke: red)

#context {
  let c = nicemat-cell("A", (1, 0))
  if c != none [Cell (1, 0) of A: page #c.page, at #c.x, #c.y.]
}
