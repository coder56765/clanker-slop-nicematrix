// Blocks, fills, rules and corners.
#import "/src/lib.typ": *
#set page(width: 16cm, height: auto, margin: 1em)
#set text(size: 12pt)
#let ex(title, body) = block(breakable: false, below: 1.2em)[*#title* #h(1fr) #body]

#ex("block + hline + vline", $ nicemat(delim: "[", column-gap: #(0.5em, 1cm, 0.5em),
  cell(A, rowspan: #3, colspan: #3), vline(), 0;
  dots.v;
  0;
  hline();
  0, dots.c, 0, 0) $)

#ex("big block (spans skip)", $ nicemat(delim: "[", hlines: #true, vlines: #true,
  cell(#text(1.6em, $A$), rowspan: #3, colspan: #3), 0;
  dots.v; 0;
  0, dots.c, 0, 0) $)

#ex("augment (compat)", $ nicemat(1, 2, 3; 4, 5, 6; 7, 8, 9, augment: #(hline: 1, vline: (1, -1), stroke: blue)) quad mat(1, 2, 3; 4, 5, 6; 7, 8, 9, augment: #(hline: 1, vline: (1, -1), stroke: blue)) $)

#ex("vlines in pmatrix", $ nicemat(vlines: #true, 1, 2, 3, 4, 5, 6; 1, 2, 3, 4, 5, 6; 1, 2, 3, 4, 5, 6) $)

#ex("double rule", $ nicearray(hlines: #true, vlines: #true,
  , a, b, c, d, e;
  hline(); hline();
  x, 0, 0, 0, 0, 0;
  y, 0, 0, 0, 0, 0;
  z, 0, 0, 0, 0, 0) $)

#ex("dashed rules", $ nicemat(1, 2, 3, 4, 5; hline(stroke: #(dash: "dashed")); 6, 7, 8, 9, 10; hline(start: #0, end: #1, stroke: #(dash: "dashed")), hline(start: #3, stroke: #(dash: "dashed")); 11, 12, 13, 14, 15) $)

#ex("fill: chessboard / rows", $ nicemat(fill: #((i, j) => if calc.even(i + j) { red.lighten(80%) } else { blue.lighten(80%) }), margin: #0.2em, 1, 2, 3; 4, 5, 6; 7, 8, 9)
  quad nicemat(fill: #((i, j) => if calc.odd(i) { luma(230) }), a, b, c; d, e, f; g, h, i; j, k, l) $)

#ex("highlighted cells", $ nicemat(margin: #0.3em,
  cell(a_(11), stroke: #blue), a_(12), a_(13), a_(14);
  a_(21), cell(a_(22), stroke: #blue), a_(23), a_(24);
  a_(31), a_(32), cell(a_(33), stroke: #blue), a_(34);
  a_(41), a_(42), a_(43), cell(a_(44), stroke: #blue)) $)


#ex("corners (Pascal)", $ nicearray(corners: #(top + right), hlines: #true, vlines: #true, 1; 1, 1; 1, 2, 1; 1, 3, 3, 1; 1, 4, 6, 4, 1; , , , , , 1) $)

#ex("corners E", $ nicearray(corners: #right, hlines: #true, vlines: #true, 1, 2; 1, 2, 3; 1, 3; 1; 1, 2, 3, 4) $)

#ex("rules skip leaders", $ nicemat(delim: "[", margin: #0.2em, hlines: #true, vlines: #true, cell(#text(1.6em, $A$), rowspan: #3, colspan: #3), 0; dots.v; 0; 0, dots.c, 0, 0) $)

#ex("rule lists without #", $ nicemat(hlines: (1, −1), vlines: 2, 1, 2, 3; 4, 5, 6; 7, 8, 9; 10, 11, 12) $)
