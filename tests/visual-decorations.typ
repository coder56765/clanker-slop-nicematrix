// Exterior rows/columns, braces, sub-matrices, regions and free leaders.
#import "/nicematrix.typ": *
#set page(width: 16cm, height: auto, margin: 1em)
#set text(size: 12pt)
#let ex(title, body) = block(breakable: false, below: 1.2em)[*#title* #h(1fr) #body]

#ex("exterior rows and columns", $ nicemat(first-row: #true, last-row: #true, first-col: #true, last-col: #true, dots: #(nullify: true),
  , C_1, dots.c, , C_4, ;
  L_1, a_(11), a_(12), a_(13), a_(14), L_1;
  dots.v, a_(21), a_(22), a_(23), a_(24), dots.v;
  , a_(31), a_(32), a_(33), a_(34), ;
  L_4, a_(41), a_(42), a_(43), a_(44), L_4;
  , C_1, dots.c, , C_4, ) $)

#ex("map-cells + hline", $ nicemat(first-row: #true, last-row: #true, first-col: #true, last-col: #true, dots: #(nullify: true),
  map-cells: #((i, j, it) => if i == 0 { text(red, it) } else if j == 0 { text(blue, it) } else if i == 5 { text(green, it) } else if j == 5 { text(fuchsia, it) } else { it }),
  , C_1, dots.c, , C_4, ;
  L_1, a_(11), a_(12), a_(13), a_(14), L_1;
  dots.v, a_(21), a_(22), a_(23), a_(24), dots.v;
  hline();
  , a_(31), a_(32), a_(33), a_(34), ;
  L_4, a_(41), a_(42), a_(43), a_(44), L_4;
  , C_1, dots.c, , C_4, ) $)

#ex("submatrices", $ nicearray(column-gap: #(0.5em, 0.5em, 0.8em), 1, 1, 1, x; frac(1, 4), frac(1, 2), frac(1, 4), y; 1, 2, 3, z;
  submatrix((0, 0), (2, 2)), submatrix((0, 3), (2, 3))) $)

#ex("submatrix sup", $ nicemat(delim: "[", 1, 1, 1; 1, a, b; 1, c, d, submatrix((1, 1), (2, 2), delim: "[", sup: T)) $)

#ex("product layout", $ nicearray(cell-space: #2pt,
  , , frac(1, 2);
  , , frac(1, 4);
  a, b, frac(1, 2) a + frac(1, 4) b;
  c, d, frac(1, 2) c + frac(1, 4) d;
  submatrix((0, 2), (1, 2)), submatrix((2, 0), (3, 1)), submatrix((2, 2), (3, 2))) $)

#ex("hbrace / vbrace in rows", $ nicearray(first-row: #true, last-row: #true, first-col: #true, last-col: #true, hlines: #true, vlines: #true,
  , hbrace(p, span: #3), hbrace(q, span: #2);
  vbrace(p, span: #3), 1, 1, 134, 1, 1, vbrace(p, span: #3);
  1, 1, 134, 1, 1;
  1, 1, 13456, 1, 1;
  vbrace(q, span: #2), 1, 1, 134, 1, 1, vbrace(q, span: #2);
  1, 1, 134, 1, 1;
  , hbrace(p, span: #3), hbrace(q, span: #2, fill: #blue)) $)

#ex("counting braces", $ nicemat(first-row: #true, last-col: #true,
  hbrace(3, span: #3), hbrace(2, span: #2);
  2, 1, 1, 1, 1, vbrace(3, span: #3);
  1, 1, 1, 1, 1;
  1, 1, 1, 1, 1;
  hline();
  1, 1, 1, 1, 1, vbrace(2, span: #2);
  1, 1, 1, 1, 1, vline(x: #3)) $)

#ex("over/under braces", $ nicemat(1, 2, 3, 4, 5, 6; 11, 12, 13, 14, 15, 16,
  hbrace((0, 0), (1, 2), A), hbrace((0, 3), (1, 5), B, shorten: #true, shift: #3pt),
  hbrace((0, 0), (1, 5), "all", side: #bottom), vbrace((0, 0), (1, 5), 2 "rows")) $)

#ex("regions", $ nicemat(
  a, a + b, a + b + c, L_1;
  a, a, a + b, L_2;
  a, a, a, L_3,
  last-col: #true,
  region((0, 0), (0, 2), fill: #red.lighten(85%), radius: #2pt),
  region((1, 0), (1, 2), fill: #red.lighten(85%), radius: #2pt),
  region((2, 0), (2, 2), fill: #red.lighten(85%), radius: #2pt)) quad
  nicemat(a_(11), a_(12), a_(13); a_(21), a_(22), a_(23); a_(31), a_(32), a_(33),
  region((0, 1), (2, 1), fit: "content", outset: #2pt, stroke: #(paint: blue, thickness: 0.6pt), radius: #3pt)) $)

#ex("dotline", $ nicemat(
  I, 0, dots.c, 0;
  0, I, dots.down, dots.v;
  dots.v, dots.down, I, 0;
  0, dots.c, 0, I,
  dotline((1, 1), (2, 2))) $)

#ex("line-style dashed + marks", $ nicemat(first-row: #true, last-col: #true, margin: #0.2em,
  dots: #(stroke: 0.5pt, marks: "<->", horizontal-labels: true),
  cdots(span: #3, above: 3), cdots(span: #2, above: 2);
  2, 1, 1, 1, 1, vdots(span: #3, above: 3);
  1, 1, 1, 1, 1;
  1, 1, 1, 1, 1;
  hline();
  1, 1, 1, 1, 1, vdots(span: #2, above: 2);
  1, 1, 1, 1, 1) $)

#ex("cell-space, column-width, baseline", $ nicemat(cell-space: #1pt, frac(1, 2), -frac(1, 2); frac(1, 3), frac(1, 4))
  quad nicemat(column-width: "equal", 1, 100; 20, 3) quad A = nicemat(baseline: #1, frac(1, sqrt(1 + p^2)), p, 1 - p; 1, 1, 1; 1, p, 1 + p) $)
