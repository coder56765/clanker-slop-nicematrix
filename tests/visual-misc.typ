// Groups, debug overlay, geometry hooks, small matrices, inline use,
// nesting, show rule and another math font.
#import "/src/lib.typ": *
#set page(width: 16cm, height: auto, margin: 1em)
#set text(size: 12pt)
#let ex(title, body) = block(breakable: false, below: 1.2em)[*#title* #h(1fr) #body]

#ex("stacked matrices (nicemat-group)", nicemat-group[
  #let mm = nicemat.with(align: right, last-col: true, vlines: 4, map-cells: (i, j, it) => if j == 5 { text(blue, $script(it)$) } else { it })
  $ mm(12, -8, 7, 5, 3, ; 3, -18, 12, 1, 4, ; -3, -46, 29, -2, -15, ; 9, 10, -5, 4, 7, ) $
  $ mm(12, -8, 7, 5, 3, ; 0, 64, -41, 1, 19, L_2 <- L_1 - 4 L_2; 0, -192, 123, -3, -57, L_3 <- L_1 + 4 L_3; 0, -64, 41, -1, -19, L_4 <- 3 L_1 - 4 L_4) $
  $ mm(12, -8, 7, 5, 3, ; 0, 64, -41, 1, 19, ; 0, 0, 0, 0, 0, L_3 <- 3 L_2 + L_3) $
  $ mm(12, -8, 7, 5, 3, ; 0, 64, -41, 1, 19, ) $
])

#ex("debug", $ nicemat(debug: #true, first-row: #true, a, b, c; 1, cell(x + y, colspan: #2); dots.v, 2, 3) $)

#ex("foreground hook (TikZ-like)", $ nicemat(
  foreground: #(g => {
    let a = g.cells.at(0).at(0)
    let b = g.cells.at(2).at(2)
    place(dx: a.ink.x - 1pt, dy: a.ink.y - 1pt, circle(radius: 3pt, stroke: red + 0.5pt))
    place(line(start: (a.ink.x + a.ink.width, a.ink.y + a.ink.height), end: (b.ink.x, b.ink.y), stroke: (paint: gray, dash: "dashed")))
  }),
  1, 0, 0; 0, 1, 0; 0, 0, 1) $)

#ex("small", [inline $mat(1, 0; 0, 1)$ vs $nicemat(small: #true, 1, 0; 0, 1)$ vs $nicemat(1, 0; 0, 1)$ in text.])

#ex("inline baseline", [Text $A = nicemat(1, dots.c, 1; dots.v, , dots.v; 1, dots.c, 1)$ and more text, $x^2 + nicemat(delim: "[", a; b) = 0$.])

#ex("nested", $ nicemat(delim: "[", nicemat(1, 2; 3, 4), 0; 0, nicemat(delim: "|", a, b; c, d)) $)

#ex("show rule", [
  #show math.mat: nicemat
  $ mat(1, dots.c, 1; dots.v, dots.down, dots.v; 1, dots.c, 1) quad mat(delim: "[", a_11, dots.c, a_(1n); dots.v, , dots.v; a_(m 1), dots.c, a_(m n)) $
])

#ex("DejaVu Math TeX Gyre", [
  #show math.equation: set text(font: "DejaVu Math TeX Gyre")
  $ nicemat(delim: "[", 1, dots.c, 1; dots.v, dots.down, dots.v; 1, dots.c, 1, augment: #(hline: 1, vline: 1)) quad mat(delim: "[", 1, dots.c, 1; dots.v, dots.down, dots.v; 1, dots.c, 1, augment: #(hline: 1, vline: 1)) $
])

#ex("code mode", [#nicemat(..range(3).map(i => range(3).map(j => $C_(#i, #j)$)), delim: "[")])
