// The documentation of the nicematrix package for Typst: getting started, a
// user guide by feature, the reference, and every mathematical example of the
// manual of the LaTeX package nicematrix, ported to Typst.
//
// Every example is evaluated: the code printed is exactly what produced the
// result next to it.
//
// Build with `typst compile --root . docs/documentation.typ`.

#import "/nicematrix.typ": *

#let scope = (
  nicemat: nicemat, nicearray: nicearray, nicemat-group: nicemat-group,
  ldots: ldots, cdots: cdots, vdots: vdots, ddots: ddots, iddots: iddots,
  cell: cell, diagbox: diagbox, hline: hline, vline: vline, hbrace: hbrace, vbrace: vbrace,
  submatrix: submatrix, region: region, dotline: dotline, connect: connect, pave: pave, flood: flood,
  nicemat-setup: nicemat-setup, nicemat-cell: nicemat-cell, nicemat-connect: nicemat-connect,
)
#let latex = json("nicematrix-latex.json")
#let ported = state("ported", ())

#set document(title: "nicematrix for Typst — documentation")
#set page(paper: "a4", margin: (x: 1.8cm, y: 2cm), numbering: "1")
#set text(size: 10.5pt)
#set par(justify: true)
#set heading(numbering: (..n) => {
  let n = n.pos()
  if n.len() == 1 { numbering("I.", n.at(0)) } else { numbering("1.1", ..n.slice(1)) }
})
#show heading.where(level: 1): it => {
  pagebreak(weak: true)
  v(2cm)
  text(size: 22pt, it)
  v(1em)
}
#show heading.where(level: 2): set block(above: 1.8em, below: 0.9em)
#show raw.where(block: true): set text(size: 7.8pt)
#show raw.where(block: false): box.with(fill: luma(242), inset: (x: 2pt), outset: (y: 2pt), radius: 2pt)
#show link: set text(fill: blue.darken(20%))

#let label-text(t) = text(size: 7pt, fill: luma(100), t)
#let code-box(code, lang: "typ", fill: rgb("#f2f6fc")) = block(
  fill: fill, inset: 6pt, radius: 3pt, width: 100%, above: 3pt,
  raw(code, block: true, lang: lang),
)
#let run(code) = eval(code.text, mode: "markup", scope: scope)

/// An example of the guide: the Typst code and its result, side by side (or
/// one below the other with `stacked: true`, for wide results).
#let example(code, title: none, note: none, stacked: false) = block(breakable: false, width: 100%, below: 1.3em, {
  if title != none { block(below: 0.5em, text(weight: "bold", title)) }
  if stacked {
    code-box(code.text)
    v(2pt)
    run(code)
  } else {
    grid(
      columns: (1fr, 1fr),
      column-gutter: 1em,
      align: (left + horizon, center + horizon),
      code-box(code.text),
      run(code),
    )
  }
  if note != none { v(2pt); text(size: 8.5pt, fill: luma(70), note) }
})

/// An example of the nicematrix manual: `id` is its line in `nicematrix.tex`.
#let ex(id, code, note: none, also: ()) = {
  ported.update(p => p + (id,) + also)
  let src = latex.at(id)
  block(breakable: false, width: 100%, stroke: 0.5pt + luma(215), radius: 3pt, inset: 7pt, below: 0.9em, {
    set text(size: 10pt)
    show raw.where(block: true): set text(size: 7.2pt)
    grid(
      columns: (1fr, 1fr),
      column-gutter: 7pt,
      {
        label-text[LaTeX — nicematrix manual, p. #src.page]
        code-box(src.code, lang: "latex", fill: luma(246))
      },
      {
        label-text[Typst]
        code-box(code.text)
      },
    )
    v(2pt)
    run(code)
    if note != none {
      v(2pt)
      text(size: 8pt, fill: luma(70), note)
    }
  })
}

// ---------------------------------------------------------------------------

#page(numbering: none)[
  #v(4cm)
  #align(center)[
    #text(size: 30pt, weight: "bold")[nicematrix for Typst]
    #v(0.5em)
    #text(size: 14pt)[Dotted leaders, blocks, rules, fills, paths, braces and sub-matrices \ for the matrices of Typst]
    #v(2cm)
    #run(```
    $ A = nicemat(delim: "[",
      first-row: #true, last-col: #true,
      C_1, dots.c, C_n, ;
      a_11, dots.c, a_(1 n), L_1;
      dots.v, dots.down, dots.v, dots.v;
      a_(m 1), dots.c, a_(m n), L_m) $
    ```)
    #v(1cm)
    #run(```
    #set text(size: 2em)
    $ nicemat(stroke: #(dash: "dashed", thickness: 1pt, paint: yellow.darken(10%)),
      delim: "[", row-gap: #0.25em, column-gap: #0.1em,
      P, a, v, e; , m, a, t,
      pave("SDS(dash: 'solid')DDD]WW"),
      pave("sdDDD", stroke: #(paint: aqua.darken(30%), dash: "solid")),
      flood((0, 0), fill: #green.transparentize(80%)),
      flood((1, 1), fill: #blue.transparentize(80%)),
      region((0, 0), (0, 0), fill: #green.transparentize(60%)),
      region((1, 1), (1, 1), fill: #blue.transparentize(60%))) $
    ```)
    #v(3cm)
    #text(size: 11pt)[
      The package `clanker-slop-nicematrix` merges the mathematical side of the
      LaTeX package #link("https://ctan.org/pkg/nicematrix")[nicematrix] and the
      paths and fills of the Typst package
      #link("https://github.com/QuadnucYard/pavemat")[pavemat].

      #v(0.5em)
      Version 0.1.0 — by akad —
      #link("https://github.com/coder56765/clanker-slop-nicematrix")
    ]
  ]
]

#outline(depth: 2)

// ===========================================================================
= Getting started
// ===========================================================================

== Introduction

A `nicemat` is written like Typst's `mat`: `,` between the cells, `;` between
the rows. Without any of the new features, it is laid out *exactly* like
`mat` (same size, same delimiters, same cells), so it can replace it anywhere.
On top of that, it provides:

- *dotted leaders*: the symbols `dots.c`, `dots.v`, `dots.down`… stretch
  between the cells, as the `\Cdots`, `\Vdots`… of nicematrix;
- *blocks*: cells spanning several rows and columns;
- *rules*: `hlines`, `vlines`, `augment`, and rules written among the cells,
  which respect the blocks, the leaders and the empty corners;
- *backgrounds*: fills by function, rectangles of cells, flood fills;
- *paths* drawn along the lines of the grid (from pavemat);
- *exterior rows and columns* for labels, *braces*, *sub-matrices*;
- *arrows* and curves between cells, even of different matrices;
- and access to the geometry of the matrix to draw anything on top of it.

The tabular side of nicematrix (`{NiceTabular}`, notes, captions…) is not
covered: Typst's `table` already does most of it.

== Installation

The package is on Typst Universe as `clanker-slop-nicematrix`; import it with:

```typ
#import "@preview/clanker-slop-nicematrix:0.1.0": *
```

Everything is exported under short names that work in math: `nicemat`,
`nicearray`, the leaders `cdots`, `vdots`…, and the markers `cell`, `hline`,
`submatrix`, `pave`… The source is at
#link("https://github.com/coder56765/clanker-slop-nicematrix").

One show rule is recommended at the top of the document, so that the matrices
of inline equations get the small cells of an inline `mat` (see
@inline):

```typ
#show: nicemat-setup
```

== A first matrix

#example(title: [Dots that stretch], ```
$ A = nicemat(delim: "[",
  a_11, a_12, dots.c, a_(1 n);
  a_21, a_22, dots.c, a_(2 n);
  dots.v, dots.v, dots.down, dots.v;
  a_(m 1), a_(m 2), dots.c, a_(m n)) $
```, note: [The dots are ordinary `dots.c`, `dots.v` and `dots.down`; inside a `nicemat` they stretch until they meet a cell.])

#example(title: [One dot command per line], ```
$ I_n = nicemat(
  1, 0, dots.c, 0;
  0, 1, , dots.v;
  dots.v, , dots.down, 0;
  0, dots.c, 0, 1) $
```, note: [Try: leave another cell empty (just `,`) and see the leader grow through it.])

== A guided tour

#example(title: [Gaussian elimination], ```
$ nicemat(last-col: #true, vlines: -1,
  align: #right,
  map-cells: #((i, j, it) => if j == 4 {
    text(blue, $script(it)$) } else { it }),
  2, 1, -1, 8, ;
  0, 1/2, 1/2, 1, L_2 <- L_2 + 3/2 L_1;
  0, 0, -1, 1, L_3 <- L_3 - 4 L_2) $
```, note: [The row operations are written in an exterior column (`last-col`); `vlines: -1` is the last rule inside the matrix. Try: `vlines: #true`, or add `hlines: #true`.])

#example(title: [Blocks and braces], ```
$ M = nicemat(delim: "[",
  first-row: #true, last-col: #true,
  hbrace(k, span: #2), hbrace(n - k, span: #2);
  cell(A, rowspan: #2, colspan: #2,
    fill: #blue.lighten(85%)), 0, 0,
    vbrace(k, span: #2);
  0, 0;
  0, 0, cell(B, rowspan: #2, colspan: #2,
    fill: #red.lighten(85%)),
    vbrace(n - k, span: #2);
  0, 0) $
```, note: [Each block is one `cell` spanning several rows and columns; the positions it covers are skipped. Try: add `stroke: #blue` to a `cell(..)`.])

#example(title: [A Jacobian with labels], ```
$ J_f = nicemat(first-row: #true,
  first-col: #true,
  map-cells: #((i, j, it) =>
    if i == 0 or j == 0 {
      text(gray.darken(40%), it) } else { it }),
  , x_1, dots.c, x_n;
  f_1, (partial f_1)/(partial x_1), dots.c,
    (partial f_1)/(partial x_n);
  dots.v, dots.v, dots.down, dots.v;
  f_m, (partial f_m)/(partial x_1), dots.c,
    (partial f_m)/(partial x_n)) $
```)

#example(title: [Highlighting and sub-matrices], ```
$ nicemat(
  1, 2, 3, 4;
  5, 6, 7, 8;
  9, 10, 11, 12,
  region((1, 0), (1, 3),
    fill: #yellow.lighten(50%), radius: #3pt),
  submatrix((0, 2), (1, 3), delim: "[",
    sup: T)) $
```, note: [Try: move the region to another row, or change its `radius`.])

#example(title: [Every `mat` becomes nice], ```
#show math.mat: nicemat
$ mat(x_1, dots.c, x_n;
  dots.v, dots.down, dots.v;
  y_1, dots.c, y_n) $
```)

#example(title: [Where is what?], ```
$ nicemat(debug: #true, first-row: #true,
  a, b, c;
  1, cell(x + y, colspan: #2);
  dots.v, 2, 3) $
```, note: [`debug` shows the position of every cell (for `region`, `submatrix`, `hbrace`…) and the numbers of the rules, on the left and above (for `hlines`, `vlines`, `augment`, `pave`). `debug: "cells"` and `debug: "rules"` show only one of them.])

#example(title: [Arrows between cells], ```
$ nicemat(column-gap: #2em, row-gap: #1em,
  a, b;
  c, d,
  connect((0, 0), (1, 1)),
  connect((0, 1), (1, 0), bend: 30,
    stroke: #blue)) $
```, note: [`connect` draws an arrow, straight or bent (like TikZ's `bend left`; negative angles bend to the right).])

== Conventions

/ Code values in math: a function called in math receives math content, so
  code values need a `#`: `#true`, `#red`, `#2pt`, `#(dash: "dashed")`.
  Small integers (`span: 3`), coordinates (`(0, 2)`) and lists of indices
  (`hlines: (1, -1)`) work without it.
/ Aliases: a function used in math needs a name of two letters or more:
  `#let mm = nicemat.with(..)` works as `$mm(..)$`, a one-letter name doesn't.
/ Cells: they are addressed `(row, col)`, from 0, *as written*, exterior rows
  and columns included. Negative numbers count from the end.
/ Rules and paths: they only exist inside the main block and are counted
  within it, like the `augment` of `mat`: the rule 0 is the top (left) border.
  A grid point `(i, j)` of a path is at the crossing of the rules `i` and `j`.
/ Spans: a spanning cell, leader or brace skips the positions it covers, as
  in `table`: don't write empty placeholders under it.
/ Rectangles: `region`, `submatrix` and the braces take two corners
  `(from, to)`, or whole rows and columns: `row: 1`, `rows: (0, 2)`,
  `col: 3`, `cols: (1, 2)`; the other direction is then the whole matrix
  (without its exterior rows and columns).
/ Outside a `nicemat`: the markers still show something sensible (a leader
  its dots, a `cell` its body, a `diagbox` $x\/y$), so a matrix stays
  readable in a plain `mat`.
/ Defaults: `#let nicemat = nicemat.with(..)` or
  `#show math.mat: nicemat.with(..)`; the `set math.mat(..)` rules
  (`delim`, `align`, `gap`, `row-gap`, `column-gap`) are honoured.

// ===========================================================================
= User guide
// ===========================================================================

== Dotted leaders

In a `nicemat`, the symbols `dots.h` (or `...`), `dots.c`, `dots.v`,
`dots.down` and `dots.up` are drawn as leaders between the nearest non-empty
cells on both sides. The empty cells in between are crossed, and consecutive
dots of the same kind make a single line. The functions `ldots`, `cdots`,
`vdots`, `ddots` and `iddots` give the same leaders with options; the option
`dots` of `nicemat` sets them for all the leaders.

#example(title: [Leaders between non-empty cells], ```
$ nicemat(delim: "[",
  a_1, dots.c, , , a_1;
  dots.v, a_2, dots.c, , a_2;
  , dots.v, ddots(fill: #red);
  ;
  a_1, a_2, , , a_n) $
```)

#example(title: [The null matrix], ```
$ nicemat(delim: "[",
  0, dots.c, dots.c, 0;
  dots.v, , , dots.v;
  dots.v, , , dots.v;
  0, dots.c, dots.c, 0) $
```)

#example(title: [Same matrix, fewer dots], ```
$ nicemat(delim: "[",
  0, dots.c, , 0;
  dots.v, , , ;
  , , , dots.v;
  0, , dots.c, 0) $
```)

#example(title: [A wider matrix], ```
$ nicemat(delim: "[",
  0, dots.c, #h(1cm), 0;
  dots.v, , , dots.v;
  0, dots.c, , 0) $
```, note: [A cell holding only `#h(..)` counts as empty (nicematrix's `\Hspace`).])

#example(title: [Leaders that take no room], ```
$ C = nicemat(h, i, j, k, l, m;
  x, dots.h, dots.h, dots.h, dots.h, x) $
$ D = nicemat(dots: #(nullify: true),
  h, i, j, k, l, m;
  x, dots.h, , , , x) $
```)

#example(title: [Leaders over several columns], ```
$ nicemat(1, 2, 3, 4, 5;
  1, cdots(span: #3), 5;
  1, 2, 3, 4, 5)
  quad
  nicemat(1, 2, 3, 4, 5;
  , cdots(span: #3);
  1, 2, 3, 4, 5) $
```, note: [With `span`, a leader covers several columns (like `\Hdotsfor`) or rows (`vdots(span: ..)`, like `\Vdotsfor`) and only looks at its neighbours.])

#example(title: [Labels], ```
$ nicemat(delim: "[",
  1, #h(1cm), 0;
  , ddots(above: n "times"), ;
  0, , 1)
  quad
  nicemat(delim: "[",
  1, #h(1cm), 0;
  , ddots(above: n "times",
    horizontal-labels: #true), ;
  0, , 1) $
```, note: [The labels are `above`, `below` and `middle` (nicematrix's `^`, `_` and `:`).])

#example(title: [Other line styles], ```
$ nicemat(dots: #(nullify: true,
    stroke: (dash: "loosely-dotted")),
  a, b, 0, , dots.c, 0;
  b, a, b, dots.down, , dots.v;
  0, b, a, dots.down, , ;
  , dots.down, dots.down, dots.down, , 0;
  dots.v, , , , , b;
  0, dots.c, , 0, b, a) $
```, note: [`stroke: auto` gives round dots; any stroke gives a line, which can get arrow tips with `marks`.])

#example(title: [Parallel diagonals], ```
$ A = nicemat(
  1, dots.c, , 1;
  a+b, dots.down, , dots.v;
  dots.v, dots.down, , ;
  a+b, dots.c, a+b, 1) $
```, note: [Diagonal leaders are drawn parallel to the first one (or to the one marked `first: #true`); `dots: (parallel: false)` turns this off.])

#example(title: [A linear system], ```
$ nicemat(vlines: -1, last-col: #true,
  dots: #(nullify: true),
  map-cells: #((i, j, it) =>
    if j == 7 { $script(it)$ } else { it }),
  1, 1, 1, dots.c, , 1, 0, ;
  0, 1, 0, dots.c, , 0, , L_2 <- L_2 - L_1;
  0, 0, 1, dots.down, , dots.v, ,
    L_3 <- L_3 - L_1;
  , , , dots.down, , , dots.v, dots.v;
  dots.v, , , dots.down, , 0, ;
  0, , , dots.c, 0, 1, 0, L_n <- L_n - L_1) $
```)

#example(title: [A leader between any two cells], ```
$ nicemat(
  I, 0, dots.c, 0;
  0, I, dots.down, dots.v;
  dots.v, dots.down, I, 0;
  0, dots.c, 0, I,
  dotline((1, 1), (2, 2))) $
```, note: [`dotline(from, to)` (nicematrix's `\line`) links two cells with the same options as the leaders.])

== Arrows and curves

`connect(from, to)` is a `dotline` drawn as an arrow: a solid line in the
color of the text with an arrow head (`marks: "->"`). Both take `bend`, an
angle (a plain number is in degrees, so math needs no `#`): the line leaves
the first cell turned by that angle to its left and reaches the second one
symmetrically, like TikZ's `bend left`; a negative angle bends to the right.

#example(title: [A commutative diagram], ```
$ nicearray(column-gap: #3em, row-gap: #2em,
  A, B;
  C, D,
  connect((0, 0), (0, 1), above: f),
  connect((0, 0), (1, 0), below: g,
    horizontal-labels: #true),
  connect((0, 1), (1, 1), above: h,
    horizontal-labels: #true),
  connect((1, 0), (1, 1), below: k),
  connect((0, 0), (1, 1), bend: -25,
    stroke: #(dash: "dashed"))) $
```, note: [The labels follow the line unless `horizontal-labels: #true`.])

#example(title: [Bent leaders], ```
$ nicemat(column-gap: #1.5em, row-gap: #1em,
  a, b, c, d;
  e, f, g, h,
  dotline((0, 0), (0, 3), bend: 25),
  connect((1, 0), (1, 3), bend: -25,
    stroke: #red, marks: "<->"),
  connect((0, 1), (1, 2), bend: 40,
    stroke: #blue)) $
```, note: [Dots are spaced evenly along a curve; `stroke`, `marks`, `shorten` and the labels work as for straight leaders, and the arrow head takes the color of the line.])

== Cells and blocks

`cell(body, ..)` gives options to a cell and lets it span several rows and
columns (`\Block`). The positions it covers are skipped, as with
`table.cell`. `diagbox(lower, upper)` slashes a cell diagonally.

#example(title: [A block], ```
$ nicemat(delim: "[", vlines: 3,
  column-gap: #(0.5em, 1cm, 0.5em),
  cell(#text(1.5em)[$A$],
    rowspan: #3, colspan: #3), 0;
  dots.v;
  0;
  hline();
  0, dots.c, 0, 0) $
```)

#example(title: [Rules skip blocks and leaders], ```
$ nicemat(delim: "[", hlines: #true,
  vlines: #true, margin: #0.2em,
  cell(#text(1.5em)[$A$],
    rowspan: #3, colspan: #3), 0;
  dots.v;
  0;
  0, dots.c, 0, 0) $
```)

#example(title: [Highlighted cells], ```
$ nicemat(margin: #0.3em, stroke: #blue,
  cell(a_11, stroke: #true), a_12, a_13;
  a_21, cell(a_22, stroke: #true), a_23;
  a_31, a_32, cell(a_33, stroke: #true)) $
```, note: [`stroke: #true` uses the stroke of the rules.])

#example(title: [Several lines in a cell], ```
$ nicemat(delim: "[", hvlines: #true,
  cell(x + y \ = z, rowspan: #2), a, b;
  c, d;
  1, "first" \ "second", 3) $
```, note: [`\` breaks a cell (or a block) into lines, set like the rows of a matrix and aligned like the cell.])

#example(title: [Diagonal boxes], ```
$ nicearray(hlines: #true, vlines: #true,
  diagbox(x, y), e, a, b;
  e, e, a, b;
  a, a, e, b;
  b, b, a, e) $
```)

== Rules and corners

The options `hlines` and `vlines` take `true` (all the rules inside, plus the
borders without delimiters), an index or a list of indices; `hvlines: #true`
gives both. `borders` forces the outer rules on (`#true`) or off (`#false`,
nicematrix's `hvlines-except-borders`). `augment` works as in `mat`. Rules can also be written among the cells: `hline()` on its own row
separates the neighbouring rows, `vline()` in a row is drawn after the cell it
follows; `start` and `end` limit them, and two markers at the same place give
a double rule.

#example(title: [Rules as markers, dashed and double], ```
$ nicearray(vlines: #true,
  , a, b, c;
  hline(); hline();
  x, 0, 0, 0;
  hline(stroke: #(dash: "dashed"));
  y, 0, 0, 0;
  hline(start: #1, end: #3,
    stroke: #(dash: "dashed"));
  z, 0, 0, 0) $
```)

#example(title: [All the rules, without the borders], ```
$ nicearray(hvlines: #true, borders: #false,
  X, O, X; O, X, O; , O, X)
  quad
  nicemat(hvlines: #true, debug: "rules",
  a, b, c; d, e, f) $
```, note: [`debug: "rules"` shows the numbers of the rules, as `hlines`, `vlines`, `augment` and `pave` count them.])

#example(title: [`augment`, as in `mat`], ```
$ nicemat(1, 2, 3; 4, 5, 6; 7, 8, 9,
  augment: #(hline: 1, vline: (1, -1),
    stroke: blue)) $
```)

#example(title: [Empty corners], ```
$ nicearray(corners: #(top + right),
  hlines: #true, vlines: #true,
  1; 1, 1; 1, 2, 1; 1, 3, 3, 1;
  1, 4, 6, 4, 1; , , , , , 1) $
```, note: [No rule is drawn in the empty corners; `corners: #true` gives the four of them, and `top`, `right`… the generalized corners.])

== Backgrounds

`fill` takes a color, an array (cycled over the columns) or a function
`(i, j) => color`; `region(from, to, ..)` covers any rectangle of cells
(`region(row: 1, ..)`, `region(cols: (0, 1), ..)` whole rows or columns), and
`flood(from, fill: ..)` fills the region bounded by paths (see the next
chapter).

#example(title: [Fills], ```
$ nicemat(margin: #0.25em,
  fill: #((i, j) => if calc.even(i + j) {
    red.lighten(85%) } else {
    blue.lighten(85%) }),
  1, 2, 3; 4, 5, 6; 7, 8, 9)
  quad
  nicemat(fill: #((i, j) =>
    if calc.odd(i) { luma(232) }),
  a, b, c; d, e, f; g, h, i; j, k, l) $
```)

#example(title: [Regions], ```
$ nicemat(last-col: #true,
  a, a + b, a + b + c, L_1;
  a, a, a + b, L_2;
  a, a, a, L_3,
  region((0, 0), (0, 2), outset: #(-1pt),
    fill: #red.lighten(85%), radius: #2pt),
  region((2, 0), (2, 2), outset: #(-1pt),
    fill: #red.lighten(85%), radius: #2pt)) $
```)

#example(title: [Whole rows and columns], ```
$ nicemat(
  1, 2, 3, 4; 5, 6, 7, 8; 9, 10, 11, 12,
  region(row: 1, radius: #2pt,
    fill: #yellow.lighten(50%)),
  region(col: -1, stroke: #red, radius: #2pt)) $
```)

#example(title: [Flood fills and single cells], ```
$ nicemat(
  1, 2, 3; 4, 5, 6; 7, 8, 9,
  flood((0, 0), fill: #red.transparentize(80%)),
  region((1, 1), (1, 1),
    fill: #blue.transparentize(80%)),
  region((2, 2), (2, 2),
    fill: #green.transparentize(80%))) $
```, note: [Without any path, the flood from `(0, 0)` covers the whole matrix; the regions of a single cell are drawn on top of it.])

== Paths along the grid

The paths of pavemat are drawn with `pave(path, ..)`. The path is a string of
directions, starting from a grid point:

- `W`, `w`: up; `S`, `s`: down; `A`, `a`: left; `D`, `d`: right.

An upper-case letter draws the segment, a lower-case letter only moves. The
grid point `(i, j)` is at the crossing of the rule `i` (above the row `i`) and
of the rule `j` (left of the column `j`), counted within the matrix like the
rules; the default is the top-left corner, and `from` takes a point or a
corner (`top + right`…). The stroke of a path is the `stroke` of the matrix
(pavemat draws dashed lines by default, so several examples below set
`stroke: #(dash: "dashed", thickness: 0.5pt)`), and `pave(.., stroke: ..)`
changes it for one path.

#example(title: [A path and a flood fill], ```
$ nicemat(
  stroke: #(dash: "dashed", thickness: 0.5pt),
  1, 2, 3; 4, 5, 6; 7, 8, 9,
  pave("DDSSAAW"),
  flood((1, 1),
    fill: #red.transparentize(80%))) $
```)

#example(title: [Drawing paths through data], ```
$ nicemat(stroke: #(blue + 1pt),
  fill: #gray.transparentize(90%),
  a, b, c; d, e, f; g, h, i,
  pave("DDSSAAW")) $
```)

#example(title: [Several styled paths], ```
$ nicemat(
  1, 2, 3, 4; 5, 6, 7, 8; 9, 10, 11, 12,
  pave("DDD", stroke: #(red + 2pt)),
  pave("SSS", from: #(top + right),
    stroke: #(blue + 2pt)),
  pave("AAA", from: #(bottom + right),
    stroke: #(green + 2pt)),
  flood((1, 1),
    fill: #yellow.transparentize(80%))) $
```)

#example(title: [The border of the matrix], ```
$ nicemat(
  stroke: #(dash: "dashed", thickness: 0.5pt),
  1, 2, 3; 4, 5, 6; 7, 8, 9,
  pave("DDSSAAWW")) $
```)

#example(title: [A flow from top-left to bottom-right], ```
$ nicemat(stroke: #(paint: green, thickness: 2pt),
  a, b, c, d; e, f, g, h; i, j, k, l,
  pave("DDDSSAAA")) $
```)

#example(title: [Hidden segments], ```
$ nicemat(stroke: #(purple + 2pt),
  debug: #true,
  alpha, beta, gamma;
  delta, epsilon, zeta;
  eta, theta, iota,
  pave("DdSs")) $
```, note: [Lower-case letters move without drawing; `debug` shows the hidden segments in gray. Hidden segments still separate the regions of `flood`.])

=== Styled segments

A group in parentheses changes the stroke of the following segments; it is
evaluated as a dictionary of stroke properties, added to the current stroke.
Groups can be nested, and `]` goes back to the previous stroke (a `[` after
the group is allowed and ignored). Single quotes are replaced by double
quotes, so there is nothing to escape.

#example(title: [A thick dotted part], ```
$ nicemat(
  stroke: #(dash: "dashed", thickness: 0.5pt),
  1, 2, 3; 4, 5, 6; 7, 8, 9,
  pave("DD(thickness: 3pt, dash: 'dotted')SS")) $
```)

#example(title: [Nested styles], ```
$ nicemat(
  stroke: #(dash: "dashed", thickness: 0.5pt),
  1, 2, 3, 4; 5, 6, 7, 8; 9, 10, 11, 12,
  pave("D(paint: red, thickness: 2pt)DD(paint: blue)S(thickness: 1pt, dash: 'dotted')S]A]A]A")) $
```, stacked: true, note: [
  `D` moves right from $(0, 0)$ to $(0, 1)$; `(paint: red, thickness: 2pt)DD`
  draws two red segments 2pt thick up to $(0, 3)$; `(paint: blue)S` goes
  down in blue (still 2pt) to $(1, 3)$; `(thickness: 1pt, dash: 'dotted')S`
  goes down to $(2, 3)$ in a dotted blue line of 1pt; each `]` then goes back
  one style: the last three segments `A` are blue 2pt, red 2pt and finally
  the dashed stroke of the matrix.
])

=== Other letters and starting points

#example(title: [`UDLR` instead of `WASD`], ```
$ nicemat(
  stroke: #(dash: "dashed", thickness: 0.5pt),
  1, 2, 3; 4, 5, 6; 7, 8, 9,
  pave("RRDDUULL", chars: #(up: "U",
    down: "D", left: "L", right: "R"))) $
```, note: [Be careful with the case: a lower-case letter is a hidden segment.])

#example(title: [Starting from the corners], ```
$ nicemat(stroke: #(blue + 1pt),
  1, 2, 3; 4, 5, 6; 7, 8, 9,
  pave("DD"),
  pave("SS", from: #(top + right)),
  pave("AA", from: #(bottom + right)),
  pave("WW", from: #(bottom + left))) $
```, note: [The grid points go from $(0, 0)$ to $(n, m)$ for a matrix of $n$ rows and $m$ columns, whose cells go from $(0, 0)$ to $(n - 1, m - 1)$.])

#example(title: [Starting from a grid point], ```
$ nicemat(stroke: #(red + 2pt),
  1, 2, 3; 4, 5, 6; 7, 8, 9,
  pave("WASSDDS", from: (1, 1))) $
```)

=== Flood fills

`flood(from, fill: ..)` fills the cells connected to the cell `from` without
crossing a path (drawn or hidden); `region((i, j), (i, j), fill: ..)` fills
a single cell. The fills are drawn in the order of the arguments, after the
`fill` of the matrix: later ones cover earlier ones.

#example(title: [A region and a single cell], ```
$ nicemat(
  stroke: #(dash: "dashed", thickness: 0.5pt),
  1, 2, 3; 4, 5, 6; 7, 8, 9,
  pave("DDSS"),
  flood((0, 0), fill: #red.transparentize(80%)),
  region((2, 2), (2, 2),
    fill: #blue.transparentize(80%))) $
```)

#example(title: [Connected regions], ```
$ nicemat(
  stroke: #(dash: "dashed", thickness: 0.5pt),
  1, 2, 3; 4, 5, 6; 7, 8, 9,
  pave("DDSSAA"),
  flood((0, 0), fill: #red.transparentize(80%)),
  region((1, 1), (1, 1),
    fill: #blue.transparentize(80%)),
  flood((-1, -1),
    fill: #green.transparentize(80%))) $
```, note: [Negative coordinates count from the end: `(-1, -1)` is the bottom-right cell.])

#example(title: [A global fill with overrides], ```
$ nicemat(
  stroke: #(dash: "dashed", thickness: 0.5pt),
  fill: #gray.transparentize(90%),
  1, 2, 3; 4, 5, 6; 7, 8, 9,
  pave("DDSSAAW"),
  region((0, 0), (0, 0),
    fill: #red.transparentize(80%)),
  flood((1, 1),
    fill: #blue.transparentize(80%))) $
```)

== Exterior rows and columns

`first-row`, `last-row`, `first-col` and `last-col` put the first or last row
or column outside the delimiters. `map-cells: (i, j, body) => body` styles any
cell (nicematrix's `code-for-first-row`, `\RowStyle`…).

#example(title: [Labels around the matrix], ```
$ nicemat(first-row: #true, last-row: #true,
  first-col: #true, last-col: #true,
  dots: #(nullify: true),
  , C_1, dots.c, , C_4, ;
  L_1, a_11, a_12, a_13, a_14, L_1;
  dots.v, a_21, a_22, a_23, a_24, dots.v;
  , a_31, a_32, a_33, a_34, ;
  L_4, a_41, a_42, a_43, a_44, L_4;
  , C_1, dots.c, , C_4, ) $
```)

#example(title: [Styling the exterior], ```
$ nicemat(first-row: #true, first-col: #true,
  map-cells: #((i, j, it) =>
    if i == 0 { text(red, it) }
    else if j == 0 { text(blue, it) }
    else { it }),
  , C_1, dots.c, C_n;
  L_1, a_11, dots.c, a_(1 n);
  dots.v, dots.v, dots.down, dots.v;
  L_m, a_(m 1), dots.c, a_(m n)) $
```)

#example(title: [Colored leaders in the exterior], ```
$ nicemat(first-row: #true, last-col: #true,
  map-cells: #((i, j, it) =>
    if i == 0 or j == 4 { text(blue, it) }
    else { it }),
  dots: #(fill: (i, j) =>
    if i == 0 or j == 4 { blue }),
  C_1, dots.c, , C_n, ;
  a_11, dots.c, , a_(1 n), L_1;
  dots.v, , , dots.v, dots.v;
  a_(n 1), dots.c, , a_(n n), L_n) $
```, note: [`fill` of the leaders can be a function of the cell where the leader starts (`none` keeps the color of the text), to follow `map-cells`.])

#example(title: [Counting rows and columns], ```
$ nicemat(first-row: #true, last-col: #true,
  margin: #0.15em,
  dots: #(stroke: 0.5pt, marks: "<->",
    horizontal-labels: true),
  cdots(span: #3, above: 3),
    cdots(span: #2, above: 2);
  2, 1, 1, vline(), 1, 1,
    vdots(span: #3, above: 3);
  1, 1, 1, 1, 1;
  1, 1, 1, 1, 1;
  hline();
  1, 1, 1, 1, 1, vdots(span: #2, above: 2);
  1, 1, 1, 1, 1) $
```)

== Braces and sub-matrices

In the exterior rows and columns, `hbrace(label, span: n)` and
`vbrace(label, span: n)` draw braces over `n` columns or rows (`\Hbrace`,
`\Vbrace`). Anywhere, `hbrace(from, to, label)` and `vbrace(from, to, label)`
draw a brace along a rectangle of cells (`\OverBrace`, `\UnderBrace`), and
`submatrix(from, to, ..)` puts delimiters around it (`\SubMatrix`). They make
room for themselves. Instead of `from, to`, they take whole rows and columns:
`hbrace(A, cols: (0, 2))`, `vbrace(B, rows: (1, 2))`, `submatrix(rows: (0, 1))`.

#example(title: [Braces in the exterior rows], ```
$ nicearray(first-row: #true,
  last-row: #true, first-col: #true,
  last-col: #true, hlines: #true,
  vlines: #true,
  , hbrace(p, span: #3), hbrace(q, span: #2);
  vbrace(p, span: #3), 1, 1, 134, 1, 1,
    vbrace(p, span: #3);
  1, 1, 134, 1, 1;
  1, 1, 13456, 1, 1;
  vbrace(q, span: #2), 1, 1, 134, 1, 1,
    vbrace(q, span: #2);
  1, 1, 134, 1, 1;
  , hbrace(p, span: #3), hbrace(q, span: #2)) $
```, note: [The braces cover the rows below them, so those rows start directly with their first cell.])

#example(title: [Braces over and under the cells], ```
$ nicemat(
  1, 2, 3, 4, 5, 6;
  11, 12, 13, 14, 15, 16,
  hbrace((0, 0), (1, 2), A),
  hbrace((0, 3), (1, 5), B),
  hbrace((0, 0), (1, 5), "all",
    side: #bottom),
  vbrace((0, 0), (1, 5), 2 "rows")) $
```)

#example(title: [Braces over whole columns and rows], ```
$ nicemat(
  1, 2, 3, 4; 5, 6, 7, 8; 9, 10, 11, 12,
  hbrace(n, cols: (0, 2)),
  hbrace(1, col: 3),
  vbrace(m, rows: (0, 1)),
  submatrix(rows: (1, 2), cols: (2, 3),
    delim: "[")) $
```)

#example(title: [Sub-matrices], ```
$ nicearray(
  1, 1, 1, x;
  frac(1, 4), frac(1, 2), frac(1, 4), y;
  1, 2, 3, z;
  submatrix((0, 0), (2, 2)),
  submatrix((0, 3), (2, 3))) $
```, note: [Room is made for the delimiters automatically (`reserve: #false` to opt out).])

#example(title: [A transposed block], ```
$ nicemat(delim: "[",
  1, 1, 1; 1, a, b; 1, c, d,
  submatrix((1, 1), (2, 2), delim: "[",
    sup: T)) $
```)

#example(title: [A product], ```
$ nicearray(cell-space: #2pt,
  , , frac(1, 2);
  , , frac(1, 4);
  a, b, frac(1, 2) a + frac(1, 4) b;
  c, d, frac(1, 2) c + frac(1, 4) d;
  submatrix((0, 2), (1, 2), slim: #true),
  submatrix((2, 0), (3, 1)),
  submatrix((2, 2), (3, 2))) $
```)

== Stacks of matrices

The matrices inside `nicemat-group[..]` share the widths of their columns and
delimiters, so that their columns line up (nicematrix's `{NiceMatrixBlock}`
with `auto-columns-width`).

#example(title: [Aligned columns], ```
#nicemat-group[
  #let rm = nicemat.with(align: right,
    last-col: true, vlines: 4,
    map-cells: (i, j, it) => if j == 5 {
      text(blue, $script(it)$) } else { it })
  $ rm(12, -8, 7, 5, 3, ;
    3, -18, 12, 1, 4, ;
    -3, -46, 29, -2, -15, ;
    9, 10, -5, 4, 7, ) $
  $ rm(12, -8, 7, 5, 3, ;
    0, 64, -41, 1, 19, L_2 <- L_1 - 4 L_2;
    0, -192, 123, -3, -57, L_3 <- L_1 + 4 L_3;
    0, -64, 41, -1, -19, L_4 <- 3 L_1 - 4 L_4) $
  $ rm(12, -8, 7, 5, 3, ;
    0, 64, -41, 1, 19, ) $
]
```)

== Inline equations <inline>

Typst sets the cells of a `mat` smaller in an inline equation, and those of
a `mat` nested in another one smaller again. A function cannot see whether it
is called in an inline equation, so `nicemat` needs one show rule for that,
at the top of the document:

#example(title: [`nicemat-setup`], ```
#show: nicemat-setup
Inline, $nicemat(1, dots.c, 1; dots.v, dots.down, dots.v; 1, dots.c, 1)$
is as small as $mat(1, dots.c, 1; dots.v, dots.down, dots.v; 1, dots.c, 1)$,
nested ones shrink as with `mat`:
$ nicemat(nicemat(1, 2; 3, 4), 0; 0, I)
  quad mat(mat(1, 2; 3, 4), 0; 0, I) $
```, stacked: true, note: [Without it, a `nicemat` always has the cells of a display equation. `small: #false` forces them; `small: #true` is the `small` of nicematrix, which also tightens the gaps and the dots.])

== Every `mat` at once, and defaults

#example(title: [A show rule], ```
#show math.mat: nicemat
$ mat(1, dots.c, 1;
  dots.v, dots.down, dots.v;
  1, dots.c, 1) $
```, note: [The show rule keeps the geometry of `mat` and turns dots into leaders (nicematrix's `renew-matrix` and `renew-dots`); `#show: nicemat-setup.with(mat: true)` does the same together with the rule for inline equations. `#show math.mat: nicemat.with(..)` or `#let nicemat = nicemat.with(..)` set defaults for a whole document.])

#example(title: [Markers in a plain `mat`], ```
$ mat(1, cdots(), 1;
  vdots(), ddots(), vdots();
  1, cdots(), 1)
  quad
  mat(diagbox(x, y), cell(a, colspan: #2)) $
```, note: [Outside a `nicemat`, the markers fall back to their plain look.])

== Drawing with the geometry

`background` and `foreground` take content or a function receiving the
geometry of the matrix (cells with their tiles and ink boxes, rows, columns,
leaders), in coordinates ready for `place`. They replace the TikZ nodes, the
`\CodeBefore` and the `\CodeAfter` of nicematrix.

#example(title: [Drawing on top], ```
$ nicemat(foreground: #(g => {
    let (a, b) = (g.cells.at(0).at(0).ink,
                  g.cells.at(2).at(2).ink)
    place(line(
      start: (a.x + a.width, a.y + a.height),
      end: (b.x, b.y),
      stroke: (paint: red, dash: "dashed")))
  }),
  1, 0, 0; 0, 1, 0; 0, 0, 1) $
```)

#example(title: [A staircase in the background], ```
$ nicearray(background: #(g => {
    let y(k) = g.rows.at(k).tile-top
    let x(k) = g.cols.at(k).tile-left
    place(polygon(fill: red.lighten(85%),
      stroke: 0.5pt,
      (x(3), y(6)), (x(3), y(7)), (x(4), y(7)),
      (x(4), y(8)), (x(5), y(8)), (x(5), y(6))))
  }),
  1; 1, 1; 1, 2, 1; 1, 3, 3, 1; 1, 4, 6, 4, 1;
  1, 5, 10, 10, 5, 1; 1, 6, 15, 20, 15, 6, 1;
  1, 7, 21, 35, 35, 21, 7, 1;
  1, 8, 28, 56, 70, 56, 28, 8, 1) $
```, stacked: true)

== Named matrices

A matrix with a `name` can be reached from outside:
`nicemat-cell(name, (i, j))` gives the position of a cell on the page (in a
`context`, `none` until the matrix is laid out), and
`nicemat-connect((name, (i, j)), (name, (i, j)))` draws between cells of
different matrices of a page, with the options of `connect` (TikZ's
`remember picture`). Put it anywhere on that page, for
instance just after the equation: it takes no room.

#example(title: [Between two matrices], ```
$ A = nicemat(name: "A", 1, 2; 3, 4)
  wide
  B = nicemat(name: "B", a, b; c, d) $
#nicemat-connect(("A", (0, 1)), ("B", (0, 0)),
  bend: 25deg, above: $T$)
#nicemat-connect(("A", (1, 1)), ("B", (1, 0)),
  bend: -20deg, stroke: auto, marks: none)
```, note: [With `stroke: auto` the line is dotted, like a leader.])

#pagebreak(weak: true)
== Showcase

These examples of pavemat mix paths, flood fills and single cells.

#example(title: [A network topology], ```
$ nicemat(delim: "|",
  "R1", "SW1", "SW2", "FW", "WAN";
  "PC1", "PC2", "SRV1", "SRV2", "ISP";
  "AP1", "AP2", "DB", "LB", "CDN";
  "IOT1", "IOT2", "STOR", "BAK", "MON";
  "DEV1", "DEV2", "TEST", "PROD", "LOG",
  // Main data path (red backbone)
  pave("DSDSDSDS", stroke: #(red + 3pt)),
  // Backup path (blue failover)
  pave("ADADADAD", from: (0, 4), stroke: #(
    paint: blue, thickness: 2pt, dash: "dashed")),
  // Network perimeter (green boundary)
  pave("DDDDSSSSAAAAWWWW", stroke: #(
    paint: green, thickness: 1pt, dash: "dotted")),
  fill: #gray.transparentize(98%),
  region((2, 2), (2, 2), fill: #orange.transparentize(70%)),
  region((0, 3), (0, 3), fill: #purple.transparentize(80%)),
  region((1, 4), (1, 4), fill: #blue.transparentize(85%))) $
```, stacked: true)

#example(title: [A binary search tree], ```
#let one(i, j, c) = region((i, j), (i, j), fill: c)
$ nicearray(
  "", 8, "", "";
  4, "", 12, "";
  2, 6, 10, 14,
  // Root to the subtrees
  pave("SA", from: (0, 1), stroke: #(blue + 2pt)),
  pave("SD", from: (0, 1), stroke: #(blue + 2pt)),
  // Left and right subtrees
  pave("S", from: (1, 0), stroke: #(green + 1.5pt)),
  pave("SD", from: (1, 0), stroke: #(green + 1.5pt)),
  pave("SA", from: (1, 2), stroke: #(red + 1.5pt)),
  pave("S", from: (1, 2), stroke: #(red + 1.5pt)),
  one(0, 1, #blue.transparentize(70%)),
  one(1, 0, #green.transparentize(75%)),
  one(1, 2, #red.transparentize(75%)),
  one(2, 0, #green.transparentize(85%)),
  one(2, 1, #green.transparentize(85%)),
  one(2, 2, #red.transparentize(85%)),
  one(2, 3, #red.transparentize(85%))) $
```, stacked: true)

#example(title: [Gaussian elimination, annotated], ```
#let one(i, j, c) = region((i, j), (i, j), fill: c)
$ nicemat(delim: "[",
  2, -1, 3, 7;
  1, 2, -1, 4;
  3, 1, 2, 10,
  // Separator before the last column
  pave("SSS", from: (0, 3), stroke: #(black + 0.5pt)),
  flood((0, 0), fill: #yellow.transparentize(90%)),
  one(0, 0, #red.transparentize(80%)),
  one(0, 3, #blue.transparentize(80%)),
  one(1, 3, #blue.transparentize(80%)),
  one(2, 3, #blue.transparentize(80%))) $
```, stacked: true)

#example(title: [A path-finding trace], ```
#let one(i, j, c) = region((i, j), (i, j), fill: c)
#let wall = gray.transparentize(40%)
$ nicemat(stroke: #(dash: "dashed", thickness: 0.5pt),
  fill: #blue.transparentize(95%),
  S, ·, ×, ·, ·;
  ·, ×, ×, ·, ×;
  ·, ·, ·, ·, G;
  ×, ×, ·, ×, ·;
  ·, ·, ·, ·, ·,
  // Optimal path with growing confidence
  pave("D(thickness: 1pt, paint: orange)D(thickness: 2pt, paint: orange)S(thickness: 3pt, paint: green)S(thickness: 3pt, paint: green)"),
  // Explored nodes (backtracking)
  pave("DSA", from: (1, 1), stroke: #(paint: gray, thickness: 1pt, dash: "dashed")),
  pave("AS", from: (2, 1), stroke: #(paint: gray, thickness: 1pt, dash: "dashed")),
  one(0, 2, #wall), one(1, 1, #wall), one(1, 2, #wall),
  one(1, 4, #wall), one(3, 0, #wall), one(3, 1, #wall),
  one(3, 3, #wall),
  one(0, 0, #green.transparentize(60%)),
  one(2, 4, #red.transparentize(60%))) $
```, stacked: true)

// ===========================================================================
= Reference
// ===========================================================================

#let ref-table(..rows) = table(
  columns: (auto, auto, 1fr),
  stroke: (x, y) => if y == 0 { (bottom: 0.6pt) } else { (bottom: 0.3pt + luma(200)) },
  inset: (x: 5pt, y: 4pt),
  table.header([*option*], [*default*], [*meaning (nicematrix / pavemat)*]),
  ..rows,
)

== `nicemat` and `nicearray`

`nicemat(..rows, ..options)` takes the rows (from the math syntax, arrays in
code, a flat list for a single row, or a `mat` element). `nicearray` is
`nicemat` with `delim: none`.

#ref-table(
  `delim`, [from `mat`], [`"("`, `"["`, `"{"`, `"|"`, `"‖"`, any extensible symbol (`"↓"`…), a pair `("[", ")")` or `none`],
  `delim-fill`, `auto`, [color of the delimiters (`delimiters/color`)],
  `align`, [from `mat`], [alignment, array (one per column, the last one repeated) or `(i, j) => alignment` (`l`/`c`/`r`, `columns-type`)],
  [`gap`, `row-gap`, `column-gap`], [from `mat`], [a length, or an array with one value per gap (`\\[..]`, `@{..}`)],
  `augment`, `none`, [as in `mat`],
  [`hlines`, `vlines`], `none`, [`true`, an index or a list of indices, counted within the matrix (`hlines`, `vlines`)],
  `hvlines`, `false`, [`true`: `hlines` and `vlines` both `true` (`hvlines`)],
  `borders`, `auto`, [outer rules of `hlines: true` / `vlines: true`: `auto` only without delimiters, `true`, `false` (`hvlines-except-borders`)],
  `stroke`, `0.05em`, [stroke of the rules and paths (`rules/color`, `rules/width`; the `stroke` of pavemat)],
  `fill`, `none`, [color, array (cycled over the columns) or `(i, j) => color` (`\rowcolors`, `\chessboardcolors`…; the global fill of pavemat)],
  `corners`, `none`, [`true` or alignments: `top + left`… and `top`, `right`… (`corners`)],
  [`first-row` … `last-col`], `false`, [exterior rows and columns],
  `map-cells`, `none`, [`(i, j, body) => body` (`code-for-first-row`, `\RowStyle`)],
  `cell-space`, `0pt`, [minimum room between the ink and the edges of the rows; length or `(top:, bottom:)` (`cell-space-limits`)],
  `margin`, `auto`, [room inside the delimiters; length or dictionary (`margin`, `extra-margin`)],
  `column-width`, `auto`, [a minimum length, one per column (`(auto, 1cm)`, like `w{c}{1cm}`), or `"equal"` (`columns-width`)],
  `baseline`, `horizon`, [`top`, `horizon`, `bottom`, a row, or `(line: k)` to put a rule on the axis (`baseline`)],
  `small`, `auto`, [`auto`: the cells of `mat` (smaller in inline equations under `nicemat-setup`, and when nested); `true`: script-style cells, tighter gaps and dots (`small`); `false`: display cells],
  `dots`, `(:)`, [options of all the leaders (`xdots/..`)],
  [`background`, `foreground`], `none`, [content or `(geometry) => content` (`\CodeBefore`, `\CodeAfter`, TikZ nodes)],
  `name`, `none`, [a name for `nicemat-cell` and `nicemat-connect` (`name`, `remember picture`)],
  `debug`, `false`, [`true`: indices and tiles of the cells, numbers of the rules, hidden path segments; `"cells"` or `"rules"` for one of them (`\ShowCellNames`; `debug`)],
)

== Leaders

`ldots`, `cdots`, `vdots`, `ddots`, `iddots` and the symbols `dots.h`,
`dots.c`, `dots.v`, `dots.down`, `dots.up`. The same options are accepted by
`nicemat(dots: (..))` for all the leaders, and by `dotline(from, to)` and
`connect(from, to)`, which also take `bend`.

#ref-table(
  `symbols`, `true`, [(in `dots` only) turn the dots symbols into leaders (`renew-dots`)],
  `span`, `1`, [(one leader) cover several columns or rows (`\Hdotsfor`, `\Vdotsfor`)],
  [`above`, `below`, `middle`], `none`, [(one leader) labels (`^`, `_`, `:`)],
  `horizontal-labels`, `false`, [keep the labels horizontal],
  `fill`, [text color], [color of the dots (`color`), or `(i, j) => color` of the cell where the leader starts (`none`: text color)],
  `stroke`, `auto`, [`auto` for round dots, or a stroke for a line (`line-style`)],
  [`radius`, `spacing`], [`0.53pt`, `0.45em`], [size and distance of the dots (`radius`, `inter`); 70% of that in small cells],
  [`shorten`, `-start`, `-end`], `0.3em`, [room at the closed ends; 70% in small cells],
  `bend`, `0`, [(`dotline`, `connect`) an angle, or a number of degrees: curve to the left (`bend left`), or to the right when negative],
  `nullify`, `false`, [the leaders take no room (`nullify`)],
  `parallel`, `true`, [(in `dots` only) parallel diagonals (`parallelize-diags`)],
  `first`, `false`, [(one leader) the reference diagonal (`draw-first`)],
  [`marks`, `mark-size`], [`none`, `4pt`], [arrow tips `"->"`, `"<-"`, `"<->"`],
  `label-fill`, [page fill], [background of the `middle` labels],
)

== Markers

Markers are written among the cells. Coordinates are `(row, col)` as written;
paths use grid points counted within the matrix.

#table(
  columns: (auto, 1fr),
  stroke: (x, y) => if y == 0 { (bottom: 0.6pt) } else { (bottom: 0.3pt + luma(200)) },
  inset: (x: 5pt, y: 4pt),
  table.header([*marker*], [*options*]),
  `cell(body)`, [`rowspan`, `colspan`, `fill`, `stroke` (`true`, a stroke, or one per side), `radius`, `outset` (length or `(x:, y:)`), `align`, `transparent` (rules cross it), `empty` (`\NotEmpty`)],
  `diagbox(lower, upper)`, [a cell slashed diagonally (`\diagbox`), also as the body of a spanning `cell`; `stroke`],
  [`hline()`, `vline()`], [`start`, `end` (excluded), `stroke`, `y` / `x` (`\Hline`, `|`, `custom-line`)],
  [`hbrace(label, span:)`, `vbrace(label, span:)`], [in exterior rows and columns (`\Hbrace`, `\Vbrace`); `fill`, `shift`],
  [`hbrace(from, to, label)`, `vbrace(from, to, label)`], [`side`, `shorten`, `shift`, `fill` (`\OverBrace`, `\UnderBrace`); `hbrace(label, cols: (a, b))` and `vbrace(label, rows: (a, b))` for whole columns or rows],
  `submatrix(from, to)`, [or `row:`, `rows:`, `col:`, `cols:`; `delim`, `sup`, `sub`, `hlines`, `vlines` (in the sub-matrix), `stroke`, `slim`, `xshift`, `left-xshift`, `right-xshift`, `extra-height`, `fill`, `reserve`, `bound` (`\SubMatrix`)],
  `region(from, to)`, [or `row:`, `rows:`, `col:`, `cols:`; `fill`, `stroke` (one per side allowed), `radius`, `outset`, `fit` (`"cells"`, `"content"`), `above` (`\rectanglecolor`; single-cell fills of pavemat)],
  `dotline(from, to)`, [the options of the leaders and `bend` (`\line`)],
  `connect(from, to)`, [a `dotline` with a solid line and an arrow head (`marks: "->"`); same options],
  `pave(path)`, [`from` (grid point or corner), `stroke`, `chars` (the paths of pavemat)],
  `flood(from)`, [`fill` (the region fills of pavemat)],
)

== Functions

#table(
  columns: (auto, 1fr),
  stroke: (x, y) => if y == 0 { (bottom: 0.6pt) } else { (bottom: 0.3pt + luma(200)) },
  inset: (x: 5pt, y: 4pt),
  table.header([*function*], [*use*]),
  [`#show: nicemat-setup`], [matrices of inline equations and nested ones sized like `mat`; `.with(mat: true)` also turns every `mat` into a `nicemat`],
  `nicemat-group[..]`, [the matrices inside share their column widths (`{NiceMatrixBlock}`, `auto-columns-width`)],
  `nicemat-cell(name, (i, j))`, [in a `context`: `none`, or the cell of a named matrix on the page: `page`, `x`, `y`, `width`, `height` (the tile), `ink` (the content), `baseline`],
  `nicemat-connect((name, (i, j)), (name, (i, j)))`, [a line between cells of named matrices on the same page; the options of `connect`],
)

== Geometry

The function given to `background` / `foreground` receives a dictionary with
`width`, `height`, `baseline`, `axis`, `main` (the rectangle of the matrix
inside its delimiters), `rows` (`top`, `baseline`, `bottom`, `tile-top`,
`tile-bottom`), `cols` (`left`, `right`, `tile-left`, `tile-right`),
`cells.at(i).at(j)` (the tile `x`, `y`, `width`, `height`, plus `ink`,
`baseline`, `empty`, `kind`, `origin`) and `leaders` (`dir`, `from`, `to`,
`open`, `start`, `end`). All the coordinates are relative to the top-left
corner of the matrix.

== Differences with nicematrix and pavemat

- The cells are set in text style, as in LaTeX and as `mat` in a display
  equation. In inline equations and nested matrices they follow `mat`
  (script style, smaller again when nested) once `#show: nicemat-setup` is
  there; Typst gives no other way to detect an inline equation.
- Typst's matrices are tighter than LaTeX's (0.5em between the columns
  instead of 10pt): the leaders over empty columns are a little shorter.
- Nothing needs a second compilation (except `nicemat-group`, which converges
  on its own).
- Sub-matrices and braces make room for themselves instead of overlapping
  their surroundings; the braces come from the math font rather than TikZ.
- The paths of pavemat use the stroke of the matrix: a stroke given to one
  path is added to it (in pavemat it replaces it), and the default is a solid
  rule rather than a dashed line. As in pavemat, a matrix with paths or flood
  fills gets a margin of half a gap around its cells (unless `margin` is
  given).
- The fills of pavemat are split between the `fill` option (global), `region`
  (a cell or a rectangle) and `flood` (a region bounded by paths); they are
  drawn in the order of the arguments.

// ===========================================================================
= The nicematrix manual, example by example
// ===========================================================================

This part takes, in order, the examples of the manual of nicematrix
(version 7.11) that concern the mathematical environments, and gives for each
one the original code (with the page of the manual where it appears), the
Typst code, and the result produced by that Typst code. The examples with
`{NiceTabular}` and those relying on TikZ decorations are listed at the end.

The LaTeX code is taken from the manual of nicematrix (© François Pantigny),
distributed under the LaTeX Project Public License 1.3c; only the `\emph{..}`
highlighting of the manual was removed.

== The vertical space between the rows

#ex("L358", ```
$ mat(frac(1, 2), -frac(1, 2);
      frac(1, 3), frac(1, 4)) $
```, note: [Typst's own `mat`, for comparison.])

#ex("L388", ```
$ nicemat(cell-space: #1pt,
  frac(1, 2), -frac(1, 2);
  frac(1, 3), frac(1, 4)) $
```)

== The vertical position of the arrays

#ex("L411", ```
$ A = nicemat(baseline: 1,
  frac(1, sqrt(1 + p^2)), p, 1 - p;
  1, 1, 1;
  1, p, 1 + p) $
```, note: [Rows are numbered from 0: `baseline=2` becomes `baseline: 1`.])

#ex("L435", ```
+ an item
+ $nicearray(baseline: #top,
    align: #(left, center),
    row-gap: #0.45em,
    margin: #(x: 0.3em, y: 0.25em),
    hline();
    n, 0, 1, 2, 3, 4, 5;
    u_n, 1, 2, 4, 8, 16, 32;
    hline())$
```, note: [`align` takes one alignment per column; the last one is repeated.])

#ex("L471", ```
+ an item
+ $nicearray(baseline: #top,
    align: #(left, center),
    row-gap: #0.6em,
    margin: #(x: 0.3em, y: 0.35em),
    hline(stroke: #0.08em);
    n, 0, 1, 2, 3, 4, 5;
    hline(stroke: #0.05em);
    u_n, 1, 2, 4, 8, 16, 32;
    hline(stroke: #0.08em))$
```, note: [The rules of booktabs are simply rules of different thicknesses.])

#ex("L508", ```
$ A = nicemat(baseline: #(line: 2),
  cell-space: #1pt, vlines: 2,
  display(1/A), display(1/B), 0, 0;
  display(1/C), display(1/D), 0, 0;
  hline();
  0, 0, A, B;
  0, 0, D, D) $
```, note: [`baseline: (line: 2)` puts the rule number 2 (counted from 0 within the matrix, like `hlines`) on the math axis.])

== The blocks

#ex("L561", ```
$ nicemat(delim: "[", margin: #(x: 5pt),
  column-width: #(auto, 1cm), vlines: 3,
  cell(A, rowspan: #3, colspan: #3), 0;
  dots.v;
  0;
  hline();
  0, dots.c, 0, 0) $
```, note: [`w{c}{1cm}` becomes a minimum width for that column. The positions covered by the block are skipped: the next rows only give their last cell.])

#ex("L583", ```
$ nicemat(delim: "[", margin: #(x: 5pt),
  column-width: #(auto, 1cm), vlines: 3,
  cell(#text(1.44em)[$A$],
    rowspan: #3, colspan: #3), 0;
  dots.v;
  0;
  hline();
  0, dots.c, 0, 0) $
```, note: [`<\Large>` becomes a `text` size. The stray `0` written under the block in the LaTeX code has no equivalent: a covered position can't hold a cell.])

#ex("L817", ```
$ nicemat(delim: "[", margin: #(x: 5pt),
  column-width: #(auto, 1cm), vlines: 3,
  cell(#text(1.728em)[$A$], align: #right,
    rowspan: #3, colspan: #3), 0;
  dots.v;
  0;
  hline();
  0, dots.c, 0, 0) $
```)

== The rules

#ex("L1173", ```
$ nicearray(vlines: 1,
  margin: #(x: 0.3em, y: 0.3em),
  hline(stroke: #0.08em);
  a, b, c, d;
  hline(stroke: #0.05em);
  1, 2, 3, 4;
  1, 2, 3, 4;
  hline(stroke: #0.08em)) $
```)

#ex("L1380", ```
$ nicemat(vlines: #true, stroke: #0.2pt,
  1, 2, 3, 4, 5, 6;
  1, 2, 3, 4, 5, 6;
  1, 2, 3, 4, 5, 6) $
```, note: [With delimiters, `vlines: #true` doesn't draw the outer rules.])

#ex("L1396", ```
$ nicearray(hlines: #true, vlines: #true,
  , vline(), vline(), a, b, c, d, e;
  hline(); hline();
  x, 0, 0, 0, 0, 0;
  y, 0, 0, 0, 0, 0;
  z, 0, 0, 0, 0, 0) $
```, note: [Two markers at the same place give a double rule, even when `hlines` / `vlines` are in force.])

#ex("L1573", ```
$ nicearray(hlines: #true, vlines: #true,
  diagbox(x, y), e, a, b, c;
  e, e, a, b, c;
  a, a, e, c, b;
  b, b, c, e, a;
  c, c, b, a, e) $
```)

#ex("L1587", ```
$ nicearray(hlines: #true, vlines: #true,
  cell(diagbox(x, y),
    rowspan: #2, colspan: #2), a, b, c;
  a, b, c;
  a, a, e, c, b;
  b, b, c, e, a;
  c, c, b, a, e) $
```)

#ex("L1602", ```
$ nicearray(hlines: #true, vlines: #true,
  cell(diagbox(x, y),
    rowspan: #2, colspan: #2), a, b, c;
  a, b, c;
  a, a, e, c, b;
  b, b, c, e, a;
  c, c, b, a, e) $
```, note: [In LaTeX, `x` and `y` are written in cells covered by the block. Covered positions can't hold cells here, so the labels are given to `diagbox`, as in the previous example.])

#ex("L1793", ```
$ nicemat(
  1, 2, 3, 4, 5;
  hline(stroke: #(dash: "dashed"));
  6, 7, 8, 9, 10;
  hline(end: #1, stroke: #(dash: "dashed")),
    hline(start: #3, stroke: #(dash: "dashed"));
  11, 12, 13, 14, 15) $
```, note: [`\cdashedline{1,4-5}`: two partial rules; `start` and `end` are columns (from 0, `end` excluded).])

#ex("L1808", ```
$ nicemat(
  1, 2, 3, 4, vline(stroke: #(dash: "dashed")), 5;
  6, 7, 8, 9, 10;
  11, 12, 13, 14, 15) $
```, note: [A `vline()` written in a row is drawn after the cell it follows.])

#ex("L1849", ```
#let myhdashedline(..args) = hline(
  stroke: (dash: "dashed"), ..args)
$ nicemat(row-gap: #(10pt, 10pt),
  1, 2, 3, 4, 5;
  myhdashedline();
  6, 7, 8, 9, 10;
  myhdashedline(end: #1),
    myhdashedline(start: #3);
  11, 12, 13, 14, 15) $
```, also: ("L1822",), note: [`custom-line` (p. 22) becomes a function. Rules never take room, so `total-width = 10pt` becomes a larger `row-gap`.])

#ex("L1884", ```
#let dotted = (thickness: 1pt,
  dash: (0pt, 3.5pt), cap: "round")
$ nicemat(
  1, 2, 3, 4, 5;
  hline(stroke: #dotted);
  6, 7, 8, 9, 10;
  hline(end: #1, stroke: #dotted),
    hline(start: #3, stroke: #dotted);
  11, 12, 13, 14, 15) $
```, note: [Round dots are a dash pattern of zero-length dashes with round caps.])

#ex("L1901", ```
#let dotted = (thickness: 1pt,
  dash: (0pt, 3.5pt), cap: "round")
$ nicemat(
  1, 2, 3, 4, vline(stroke: #dotted), 5;
  6, 7, 8, 9, 10;
  11, 12, 13, 14, 15) $
```)

== The color of the background of the rows and columns

#ex("L2407", ```
$ nicemat(align: #right, margin: #(x: 5pt),
  fill: #((i, j) => if calc.even(i + j) {
    red.lighten(85%) } else { blue.lighten(85%) }),
  1, -1, 1;
  -1, 1, -1;
  1, -1, 1) $
```, note: [`\chessboardcolors`, `\rowcolors`, `\columncolor`… are all functions `(i, j) => color`.])

#ex("L2431", ```
$ nicearray(align: #left,
  hlines: #true, vlines: #true,
  fill: #((i, j) => if i + 1 in (1, 3, 4, 5)
    or i + 1 >= 8 { red.lighten(85%) }),
  a_1, b_1, c_1;
  a_2, b_2, c_2;
  a_3, b_3, c_3;
  a_4, b_4, c_4;
  a_5, b_5, c_5;
  a_6, b_6, c_6;
  a_7, b_7, c_7;
  a_8, b_8, c_8;
  a_9, b_9, c_9;
  a_10, b_10, c_10) $
```, note: [`\rowcolor{red!15}{1,3-5,8-}`, with the row numbers of the manual.])

== The width of the columns

#ex("L2903", ```
$ nicemat(column-width: #1cm,
  1, 12, -123;
  12, 0, 0;
  4, 1, 2) $
```)

#ex("L2927", ```
$ nicemat(column-width: "equal",
  1, 12, -123;
  12, 0, 0;
  4, 1, 2) $
```)

#ex("L2942", ```
#let nm = nicemat.with(column-width: 10mm)
$ nm(a, b; c, d) = nm(1, 1245; 345, 2) $
```, note: [`\NiceMatrixOptions` becomes `.with`. (A function used in math needs a name of two letters or more.)])

#ex("L2966", ```
#nicemat-group[
  $ vec(delim: #none, gap: #1em,
    nicemat(delim: "[", 9, 17; -2, 5),
    nicemat(delim: "[", 1, 1245345; 345, 2)) $
]
```, note: [`{NiceMatrixBlock}[auto-columns-width]` becomes `nicemat-group`.])

== The exterior rows and columns

#ex("L3136", ```
$ nicemat(first-row: #true, last-row: #true,
  first-col: #true, last-col: #true,
  dots: #(nullify: true),
  , C_1, dots.c, , C_4, ;
  L_1, a_11, a_12, a_13, a_14, L_1;
  dots.v, a_21, a_22, a_23, a_24, dots.v;
  , a_31, a_32, a_33, a_34, ;
  L_4, a_41, a_42, a_43, a_44, L_4;
  , C_1, dots.c, , C_4, ) $
```)

#ex("L3205", ```
$ nicemat(first-row: #true, last-row: #true,
  first-col: #true, last-col: #true,
  vlines: 2, dots: #(nullify: true),
  map-cells: #((i, j, it) => {
    let c = if i == 0 { red } else if i == 5 { green }
      else if j == 0 { blue } else if j == 5 { fuchsia }
    if c == none { it } else { text(fill: c, it) }
  }),
  , C_1, cdots(fill: #red), , C_4, ;
  L_1, a_11, a_12, a_13, a_14, L_1;
  vdots(fill: #blue), a_21, a_22, a_23, a_24,
    vdots(fill: #fuchsia);
  hline();
  , a_31, a_32, a_33, a_34, ;
  L_4, a_41, a_42, a_43, a_44, L_4;
  , C_1, cdots(fill: #green), , C_4, ) $
```, note: [`code-for-first-row` & co. become `map-cells`; the leaders get their color directly.])

== Dotted leaders in the matrices

#ex("L3285", ```
$ nicemat(delim: "[",
  a_1, dots.c, , , a_1;
  dots.v, a_2, dots.c, , a_2;
  , dots.v, ddots(fill: #red);
  ;
  a_1, a_2, , , a_n) $
```, note: [The dots symbols of Typst are the leaders: `dots.c`, `dots.h` (or `...`), `dots.v`, `dots.down`, `dots.up`; the functions `cdots(..)` & co. take options.])

#ex("L3300", ```
$ nicemat(delim: "[",
  0, dots.c, 0;
  dots.v, , dots.v;
  0, dots.c, 0) $
```)

#ex("L3315", ```
$ nicemat(delim: "[",
  0, dots.c, dots.c, 0;
  dots.v, , , dots.v;
  dots.v, , , dots.v;
  0, dots.c, dots.c, 0) $
```)

#ex("L3334", ```
$ nicemat(delim: "[",
  0, dots.c, , 0;
  dots.v, , , ;
  , , , dots.v;
  0, , dots.c, 0) $
```)

#ex("L3361", ```
$ nicemat(delim: "[", row-gap: #(0.2em, 1cm),
  0, dots.c, #h(1cm), 0;
  dots.v, , , dots.v;
  0, dots.c, , 0) $
```, note: [A cell holding only `#h(..)` counts as empty (`\Hspace`); `\\[1cm]` becomes a gap in `row-gap`.])

#ex("L3381", ```
$ A = mat(h, i, j, k, l, m;
  x, , , , , x) $
```, note: [Typst's own `mat`, for comparison.])

#ex("L3394", ```
$ B = mat(h, i, j, k, l, m;
  x, dots.h, dots.h, dots.h, dots.h, x) $
```, note: [Typst's own `mat`, for comparison.])

#ex("L3408", ```
$ C = nicemat(h, i, j, k, l, m;
  x, dots.h, dots.h, dots.h, dots.h, x) $
```)

#ex("L3424", ```
$ D = nicemat(dots: #(nullify: true),
  h, i, j, k, l, m;
  x, dots.h, , , , x) $
```)

#ex("L3457", ```
$ nicemat(
  1, 2, 3, 4, 5;
  1, cdots(span: #3), 5;
  1, 2, 3, 4, 5;
  1, 2, 3, 4, 5) $
```, note: [`\Hdotsfor{3}` is a leader with a `span`.])

#ex("L3471", ```
$ nicemat(
  1, 2, 3, 4, 5;
  , cdots(span: #3);
  1, 2, 3, 4, 5;
  1, 2, 3, 4, 5) $
```)

#ex("L3497", ```
#set text(size: 9pt)
$ nicemat(delim: "[",
  C[a_1\, a_1], dots.c, C[a_1\, a_n], #h(20mm),
    C[a_1\, a_1^((p))], dots.c, C[a_1\, a_n^((p))];
  dots.v, dots.down, dots.v, cdots(span: #1),
    dots.v, dots.down, dots.v;
  C[a_n\, a_1], dots.c, C[a_n\, a_n], ,
    C[a_n\, a_1^((p))], dots.c, C[a_n\, a_n^((p))];
  cell(#box(height: 15mm), empty: #false),
    vdots(span: #1), , dots.down, , vdots(span: #1);
  C[a_1^((p))\, a_1], dots.c, C[a_1^((p))\, a_n], ,
    C[a_1^((p))\, a_1^((p))], dots.c,
    C[a_1^((p))\, a_n^((p))];
  dots.v, dots.down, dots.v, cdots(span: #1),
    dots.v, dots.down, dots.v;
  C[a_n^((p))\, a_1], dots.c, C[a_n^((p))\, a_n], ,
    C[a_n^((p))\, a_1^((p))], dots.c,
    C[a_n^((p))\, a_n^((p))]) $
```, note: [A comma inside a cell is escaped with `\,`. `\Vdotsfor{1}` is `vdots(span: 1)`; `\rule{0pt}{15mm}\NotEmpty` is a tall box in a cell forced to count as non-empty.])

#ex("L3556", ```
#show math.mat: nicemat
$ mat(
  1, dots.c, dots.c, 1;
  0, dots.down, , dots.v;
  dots.v, dots.down, dots.down, dots.v;
  0, dots.c, 0, 1) $
```, note: [`renew-matrix` and `renew-dots` are a single show rule: every `mat` becomes a `nicemat`, with the same geometry.])

#ex("L3587", ```
$ nicemat(delim: "[", row-gap: #(8mm, 0.2em),
  1, #h(1cm), 0;
  , ddots(above: n "times"), ;
  0, , 1) $
```, note: [The labels `^`, `_` and `:` are `above`, `below` and `middle`.])

#ex("L3600", ```
$ nicemat(delim: "[", row-gap: #(8mm, 0.2em),
  1, #h(1cm), 0;
  , ddots(above: n "times",
      horizontal-labels: #true), ;
  0, , 1) $
```)

#ex("L3736", ```
$ nicemat(dots: #(nullify: true,
    shorten: 0.3em + 2pt,
    stroke: (dash: "loosely-dotted")),
  a, b, 0, , dots.c, 0;
  b, a, b, dots.down, , dots.v;
  0, b, a, dots.down, , ;
  , dots.down, dots.down, dots.down, , 0;
  dots.v, , , , , b;
  0, dots.c, , 0, b, a) $
```, note: [`line-style` becomes `stroke`: `auto` gives the round dots of nicematrix, any Typst stroke gives a line.])

#ex("L3761", ```
$ nicemat(delim: "[", margin: #(x: 5pt),
  hlines: #true, vlines: #true,
  column-width: #(auto, 1cm),
  cell(#text(1.728em)[$A$],
    rowspan: #3, colspan: #3), 0;
  dots.v;
  0;
  0, dots.c, 0, 0) $
```, note: [The rules are not drawn in the block nor across the leaders. The `\hspace*{1cm}` written under the block becomes a column width.])

#ex("L3835", ```
$ nicearray(first-row: #true,
  last-row: #true, first-col: #true,
  last-col: #true, hlines: #true,
  vlines: #true,
  , hbrace(p, span: #3),
    hbrace(q, span: #2, shift: #1mm);
  vbrace(p, span: #3), 1, 1, 134, 1, 1,
    vbrace(p, span: #3);
  1, 1, 134, 1, 1;
  1, 1, 13456, 1, 1;
  vbrace(q, span: #2), 1, 1, 134, 1, 1,
    vbrace(q, span: #2);
  1, 1, 134, 1, 1;
  , hbrace(p, span: #3),
    hbrace(q, span: #2, fill: #blue)) $
```, note: [The braces cover the rows below them, so those rows start directly with their first cell. They are drawn with the braces of the math font (TikZ decorations have no equivalent).])

== Delimiters in the preamble of the environment

#ex("L3910", ```
$ nicearray(
  1, 2, 3, ;
  4, 1, 6, ;
  7, 8, 9, script(L_3 <- L_3 + L_1 + L_2),
  submatrix((0, 0), (2, 2), delim: "⟮")) $
```, note: [Delimiters in the preamble are sub-matrices; they make room for themselves.])

#ex("L3971", ```
$ nicemat(
  a_11, a_12, a_13;
  a_21, display(integral_0^1 1/(x^2 + 1) dif x),
    a_23;
  a_31, a_32, a_33,
  submatrix((0, 0), (2, 0)),
  submatrix((0, 1), (2, 1)),
  submatrix((0, 2), (2, 2))) $
```)

== The \\CodeAfter

#ex("L4051", ```
$ nicemat(
  I, 0, dots.c, 0;
  0, I, dots.down, dots.v;
  dots.v, dots.down, I, 0;
  0, dots.c, 0, I,
  dotline((1, 1), (2, 2))) $
```, note: [`\line` becomes the `dotline` decoration. The shortening is left at its default: Typst's matrices are tighter than LaTeX's and `shorten += 0.3em` would leave no room for the dots.])

#ex("L4067", ```
$ nicemat(delim: "[",
  1, dots.c, , 1, 2, dots.c, 2;
  0, dots.down, , dots.v, dots.v, #h(2.5cm),
    dots.v;
  dots.v, dots.down, , , , , ;
  0, dots.c, 0, 1, 2, dots.c, 2,
  dotline((0, 4), (3, 6), shorten: #6pt)) $
```)

#ex("L4117", ```
$ nicearray(cell-space: #2pt,
  1, 1, 1, x;
  display(1/4), display(1/2), display(1/4), y;
  1, 2, 3, z,
  submatrix((0, 0), (2, 2)),
  submatrix((0, 3), (2, 3))) $
```, note: [No manual spacing is needed: a sub-matrix makes room for its delimiters (`reserve: #false` to opt out).])

#ex("L4134", ```
$ nicearray(cell-space: #2pt,
  1, 1, 1, x;
  display(1/4), display(1/2), display(1/4), y;
  1, 2, 3, z,
  submatrix((0, 0), (2, 2)),
  submatrix((0, 3), (2, 3))) $
```, note: [The preamble `(ccc)(c)` is the same thing as the two sub-matrices above.])

#ex("L4151", ```
$ nicemat(delim: "[",
  1, 1, 1;
  1, a, b;
  1, c, d,
  submatrix((1, 1), (2, 2), delim: "[",
    sup: T)) $
```)

#ex("L4210", ```
$ nicearray(cell-space: #2pt,
  align: #(center, center, left),
  column-gap: #(0.5em, 5mm),
  row-gap: #(0.2em, 1mm + 0.2em, 0.2em),
  , , 1/2;
  , , 1/4;
  a, b, 1/2 a + 1/4 b;
  c, d, 1/2 c + 1/4 d,
  submatrix((0, 2), (1, 2)),
  submatrix((2, 0), (3, 1)),
  submatrix((2, 2), (3, 2))) $
```)

#ex("L4227", ```
$ nicearray(cell-space: #2pt,
  align: #(center, center, left),
  column-gap: #(0.5em, 5mm),
  row-gap: #(0.2em, 1mm + 0.2em, 0.2em),
  , , 1/2;
  , , 1/4;
  a, b, 1/2 a + 1/4 b;
  c, d, 1/2 c + 1/4 d,
  submatrix((0, 2), (1, 2), slim: #true),
  submatrix((2, 0), (3, 1)),
  submatrix((2, 2), (3, 2))) $
```)

#ex("L4290", ```
// Rules under the diagonal of the 3×3 sub-matrix at (i, j),
// like `(2-|1) -| (3-|2) -| (4-|3)` relative to the sub-matrix.
#let stairs(g, i, j) = {
  let y(k) = if k < g.rows.len() { g.rows.at(k).tile-top } else { g.rows.last().tile-bottom }
  // The left edge of the sub-matrix is just inside its delimiter.
  let x(k) = if k == j { g.cols.at(k).left - 2pt } else { g.cols.at(k).tile-left }
  place(curve(stroke: blue,
    curve.move((x(j), y(i + 1))),
    curve.line((x(j + 1), y(i + 1))), curve.line((x(j + 1), y(i + 2))),
    curve.line((x(j + 2), y(i + 2))), curve.line((x(j + 2), y(i + 3)))))
}
$ nicearray(
  column-width: #(auto, auto, auto, 5mm),
  column-gap: #(0.5em, 0.5em, 0pt, 0pt, 0.5em, 0.5em),
  foreground: #(g => {
    stairs(g, 0, 4); stairs(g, 3, 0); stairs(g, 3, 4) }),
  , , , , -1, 1, 2;
  , , , , 0, 3, 4;
  , , , , 0, 0, 5;
  1, 2, 3, , -1, 7, 25;
  0, 4, 5, , 0, 12, 41;
  0, 0, 6, , 0, 0, 30,
  submatrix((0, 4), (2, 6)),
  submatrix((3, 0), (5, 2)),
  submatrix((3, 4), (5, 6))) $
```, note: [The `code` key of `\SubMatrix` (TikZ code relative to the sub-matrix) becomes a function using the geometry of the matrix.])

#ex("L4341", ```
$ nicemat(
  1, 2, 3, 4, 5, 6;
  11, 12, 13, 14, 15, 16,
  hbrace((0, 0), (1, 2), A),
  hbrace((0, 3), (1, 5), B)) $
```, note: [`\OverBrace` is `hbrace(from, to, label)` (and `\UnderBrace` has `side: bottom`). Room is made for the braces.])

#ex("L4388", ```
$ nicemat(
  1, 2, 3, 4, 5, 6;
  11, 12, 13, 14, 15, 16,
  hbrace((0, 0), (1, 2), A,
    shorten: #true, shift: #3pt),
  hbrace((0, 3), (1, 5), B,
    shorten: #true, shift: #3pt)) $
```)

== Other features

#ex("L5098", ```
$ nicemat(first-row: #true,
  dots: #(nullify: true),
  align: #(right, center),
  column-width: #(auto, auto, 1cm),
  C_1, dots.c, , C_n;
  2.3 #hide[$0$], 0, dots.c, 0;
  12.4 #hide[$0$], dots.v, , dots.v;
  1.45;
  7.2 #hide[$0$], 0, dots.c, 0) $
```, note: [Typst has no column of type `S`: the decimal points are aligned here with right alignment and a hidden digit.])

#ex("L5128", ```
$ nicemat(delim: "[", align: #right,
  cos x, -sin x;
  sin x, cos x) $
```)

#ex("L5159", ```
$ A = nicemat(first-row: #true,
  last-col: #true,
  map-cells: #((i, j, it) => if i == 0 {
      rotate(-90deg, reflow: true,
        $script("image of " #it)$)
    } else if j == 3 { $script(#it)$ }
    else { it }),
  e_1, e_2, e_3;
  1, 2, 3, e_1;
  4, 5, 6, e_2;
  7, 8, 9, e_3) $
```, note: [`\rotate` is Typst's `rotate`.])

#ex("L5198", ```
$ A = nicemat(last-row: #true,
  last-col: #true,
  map-cells: #((i, j, it) => if i == 3 {
      box(baseline: 100%, rotate(-90deg,
        reflow: true, $script(#it)$))
    } else if j == 3 { $script(#it)$ }
    else { it }),
  1, 2, 3, e_1;
  4, 5, 6, e_2;
  7, 8, 9, e_3;
  "image of " e_1, e_2, e_3) $
```, note: [`box(baseline: 100%)` hangs the rotated labels from the top of the row.])

#ex("L5254", ```
$ nicemat(delim: "[", small: #true,
  last-col: #true, vlines: 4,
  column-width: #3mm,
  map-cells: #((i, j, it) =>
    if j == 5 { $sscript(#it)$ } else { it }),
  1, -2, 3, 4, 5, ;
  0, 3, 2, 1, 2, L_2 <- 2 L_1 - L_2;
  0, 1, 1, 2, 3, L_3 <- L_1 + L_3) $
```)

#ex("L5311", ```
$ nicemat(first-row: #true, first-col: #true,
  map-cells: #((i, j, it) =>
    if i == 0 and j > 0 { $bold(#numbering("a", j))$ }
    else if j == 0 and i > 0 { $bold(#str(i))$ }
    else { it }),
  , , , , ;
  , 1, 2, 3, 4;
  , 5, 6, 7, 8;
  , 9, 10, 11, 12) $
```, note: [The counters `iRow` and `jCol` are the arguments of `map-cells`.])

#ex("L5348", ```
$ C = #nicemat(..range(3).map(i =>
  range(3).map(j => $C_(#(i + 1), #(j + 1))$))) $
```, note: [`\AutoNiceMatrix` is an array built in code.])

#ex("L5374", ```
$ nicemat(delim: "[",
  first-row: #true, first-col: #true,
  , a, b;
  a, 2 cos a, cos a + cos b;
  b, cos a + cos b, 2 cos b) $
```, note: [`light-syntax` has no purpose: the syntax of Typst is already light.])

#ex("L5416", ```
$ nicemat(delim: "[", delim-fill: #red,
  1, 2;
  3, 4) $
```)

#ex("L5443", ```
$ nicemat(delim: #("↓", "↑"),
  margin: #(x: 5pt),
  1, 2, 3;
  4, 5, 6;
  7, 8, 9) $
```, note: [`{NiceArrayWithDelims}` is `delim` with a pair; any extensible symbol can be used.])

== Explicit use of TikZ with nicematrix

#ex("L5538", ```
$ nicemat(foreground: #(g => {
    let c = g.cells.at(1).at(1).ink
    place(dx: c.x + c.width / 2 - 2mm,
      dy: c.y + c.height / 2 - 2mm,
      circle(radius: 2mm))
  }),
  1, 2, 3;
  4, 5, 6;
  7, 8, 9) $
```, also: ("L5558",), note: [The TikZ nodes (named, or used in the `\CodeAfter`, p. 55) are the geometry given to `foreground`: `ink` is the content of a cell, `x`, `y`, `width`, `height` its tile.])

#ex("L5904", ```
$ nicearray(column-gap: #0.28em,
  row-gap: #((0.2em,) * 5 + (0.2em + 3pt,)),
  dots: #(symbols: false),
  foreground: #(g => for i in range(5) {
    let (a, b) = (g.cells.at(i).at(0),
                  g.cells.at(i + 1).at(2))
    place(line(start: (a.x, a.y),
      end: (b.x + b.width, b.y + b.height),
      stroke: (paint: red.transparentize(60%),
               thickness: 3pt)))
  }),
  u_1, -, u_0, =, r;
  u_2, -, u_1, =, r;
  u_3, -, u_2, =, r;
  u_4, -, u_3, =, r;
  #hide($u_5$), , #hide($u_4$), dots.v, ;
  u_n, -, u_(n-1), =, r;
  hline();
  u_n, -, u_0, =, n r) $
```, note: [The "medium nodes" are the tiles of the cells, which reach the middle of the gaps.])

#ex("L5966", ```
$ nicearray(background: #(g => {
    let y(k) = g.rows.at(k).tile-top
    let x(k) = g.cols.at(k).tile-left
    place(polygon(fill: red.lighten(85%),
      stroke: 0.5pt,
      (x(3), y(6)), (x(3), y(7)), (x(4), y(7)),
      (x(4), y(8)), (x(5), y(8)), (x(5), y(6))))
  }),
  1;
  1, 1;
  1, 2, 1;
  1, 3, 3, 1;
  1, 4, 6, 4, 1;
  1, 5, 10, 10, 5, 1;
  1, 6, 15, 20, 15, 6, 1;
  1, 7, 21, 35, 35, 21, 7, 1;
  1, 8, 28, 56, 70, 56, 28, 8, 1) $
```, note: [The nodes `i-|j` of the rules are the edges of the tiles (`tile-top`, `tile-left`, …).])

#ex("L5989", ```
$ nicemat(vlines: 3, foreground: #(g => {
    let r = g.rows.at(2)
    let y = r.tile-top + 0.4 * (r.tile-bottom - r.tile-top)
    place(line(start: (g.main.x, y),
      end: (g.main.x + g.main.width, y), stroke: red))
  }),
  2, 1, 3, 0;
  3, 3, 1, 0;
  3, 3, 1, 0) $
```)

== Technical remarks

#ex("L6206", ```
$ A = nicemat(
  1, dots.c, , 1;
  a+b, ddots(fill: #red), , dots.v;
  dots.v, dots.down, , ;
  a+b, dots.c, a+b, 1) $
```, note: [The first diagonal leader (here in red) gives the direction of the others.])

#ex("L6216", ```
$ A = nicemat(
  1, dots.c, , 1;
  a+b, , , dots.v;
  dots.v, ddots(fill: #red), dots.down, ;
  a+b, dots.c, a+b, 1) $
```, note: [Same algorithm as nicematrix, but Typst's tighter columns make the first diagonal (in red) steeper, so the line parallel to it runs past the matrix; `dots: (parallel: false)` or wider columns avoid that.])

== Examples

#ex("L6658", ```
#text(fill: blue, $ nicearray(
  column-width: #1cm, stroke: #black,
  hlines: #true, vlines: #true,
  map-cells: #((i, j, it) =>
    if j == 0 { text(black, it) } else { it }),
  f(x), cell(+, colspan: #5);
  f'(x), cell(+, colspan: #2),
    cell(+, colspan: #2), +;
  f''(x), -, cell(-, colspan: #2),
    cell(+, colspan: #2)) $)
```, note: [A sign chart.])

#ex("L6685", ```
$ nicearray(cell-space: #2pt, vlines: 1,
  align: #(right, center),
  column-width: #(auto, auto, 1cm, auto, 1cm),
  foreground: #(g => {
    let y(k) = g.rows.at(k).tile-top
    let m = g.cols.at(3)
    let x = (m.tile-left + m.tile-right) / 2
    place(line(start: (x, y(2)), end: (x, y(4))))
    let x = g.cols.at(1).tile-left + 3pt
    place(line(start: (x, y(1)), end: (x, y(2))))
  }),
  x, 0, -, 1/e, +, +oo;
  hline();
  f'(x), , -, 0, +, ;
  hline();
  , 1, , , , +oo;
  f, , , , , ;
  , , , (1\/e)^(1\/e),
  connect((2, 1), (4, 3), stroke: #red,
    shorten-start: #3pt),
  connect((4, 3), (2, 5), stroke: #red,
    shorten-start: #3pt)) $
```, note: [A variation table: the arrows are `connect`s; `\/` is a slash that doesn't make a fraction.])

#ex("L6748", ```
#let dot = (dash: "dotted")
$ nicemat(
  1, 2, 0, 0, 0, 0;
  4, 5, 0, 0, 0, 0;
  0, 0, 7, 1, 0, 0;
  0, 0, -1, 2, 0, 0;
  0, 0, 0, 0, 3, 4;
  0, 0, 0, 0, 1, 4,
  region((0, 0), (1, 1),
    stroke: #(bottom: dot, right: dot)),
  region((2, 2), (3, 3), stroke: #dot),
  region((4, 4), (5, 5),
    stroke: #(left: dot, top: dot))) $
```, note: [The key `borders` of `\Block` is a stroke per side, as for `rect`.])

#ex("L6782", ```
$ nicemat(delim: "|", column-width: #6mm,
  cell-space: #(top: 1mm),
  dots: #(shorten: 0.3em + 3pt),
  a_0, , , , vline(stroke: #(dash: "dashed")),
    b_0, , ;
  a_1, dots.down, , , b_1, dots.down, ;
  dots.v, dots.down, , , dots.v, dots.down, b_0;
  a_p, , , a_0, , , b_1;
  , dots.down, , a_1, b_q, , dots.v;
  , , , dots.v, , dots.down, ;
  , , , a_p, , , b_q) $
```, note: [The resultant of two polynomials.])

#ex("L6805", ```
$ nicemat(vlines: -1, last-col: #true,
  dots: #(nullify: true),
  map-cells: #((i, j, it) =>
    if j == 7 { $script(#it)$ } else { it }),
  1, 1, 1, dots.c, , 1, 0, ;
  0, 1, 0, dots.c, , 0, , L_2 <- L_2 - L_1;
  0, 0, 1, dots.down, , dots.v, , L_3 <- L_3 - L_1;
  , , , dots.down, , , dots.v, dots.v;
  dots.v, , , dots.down, , 0, ;
  0, , , dots.c, 0, 1, 0, L_n <- L_n - L_1) $
```, note: [A linear system. `vlines: -1` is the last rule inside the matrix.])

#ex("L6840", ```
#let bl(x) = text(fill: blue, x)
#set text(size: 9pt)
$ nicemat(last-row: #true, last-col: #true,
  dots: #(nullify: true,
    stroke: (paint: blue, dash: "dashed")),
  1, , , dots.v, , , , dots.v;
  , ddots(stroke: #auto);
  , , 1;
  dots.c, , , bl(0), dots.c, , , bl(1), , ,
    dots.c, bl(<- i);
  , , , , 1;
  , , , dots.v, , ddots(stroke: #auto), , dots.v;
  , , , , , , 1;
  dots.c, , , bl(1), dots.c, , dots.c, bl(0), , ,
    dots.c, bl(<- j);
  , , , , , , , , 1;
  , , , , , , , , , ddots(stroke: #auto);
  , , , dots.v, , , , dots.v, , , 1;
  , , , bl(limits(i)^arrow.t), , , ,
    bl(limits(j)^arrow.t)) $
```, note: [Leaders that are no longer dotted; `stroke: #auto` gives back the dots for one leader.])

#ex("L6869", ```
$ nicemat(first-row: #true, last-col: #true,
  margin: #(x: 5pt), vlines: 3,
  dots: #(horizontal-labels: true,
    stroke: 0.5pt, marks: "<->"),
  cdots(span: #3, above: 3),
    cdots(span: #2, above: 2);
  2, 1, 1, 1, 1, vdots(span: #3, above: 3);
  1, 1, 1, 1, 1;
  1, 1, 1, 1, 1;
  hline();
  1, 1, 1, 1, 1, vdots(span: #2, above: 2);
  1, 1, 1, 1, 1) $
```, note: [Illustrating the numbers of rows and columns: `line-style = <->` is a stroke with `marks`.])

#ex("L6890", ```
$ nicemat(first-row: #true, last-col: #true,
  margin: #(x: 5pt), vlines: 3,
  dots: #(horizontal-labels: true,
    stroke: 0.5pt, marks: "<->"),
  cdots(span: #3, middle: 3),
    cdots(span: #2, middle: 2);
  2, 1, 1, 1, 1, vdots(span: #3, middle: 3);
  1, 1, 1, 1, 1;
  1, 1, 1, 1, 1;
  hline();
  1, 1, 1, 1, 1,
    vdots(span: #2, middle: 2 "rows");
  1, 1, 1, 1, 1) $
```)

#ex("L6919", ```
$ nicemat(first-row: #true, last-col: #true,
  margin: #(x: 5pt), vlines: 3,
  hbrace(3, span: #3), hbrace(2, span: #2);
  2, 1, 1, 1, 1, vbrace(3, span: #3);
  1, 1, 1, 1, 1;
  1, 1, 1, 1, 1;
  hline();
  1, 1, 1, 1, 1, vbrace(2, span: #2);
  1, 1, 1, 1, 1) $
```)

#ex("L6988", ```
$ nicemat(last-col: #true, margin: #(x: 5pt),
  vlines: 3,
  2, 1, 1, 1, 1, cell(quad 3, rowspan: #3);
  1, 1, 1, 1, 1;
  1, 1, 1, 1, 1;
  hline();
  1, 1, 1, 1, 1, cell(quad 2, rowspan: #2);
  1, 1, 1, 1, 1,
  hbrace((0, 0), (0, 2), 3,
    shorten: #true, shift: #1.5mm),
  hbrace((0, 3), (0, 4), 2,
    shorten: #true, shift: #1.5mm),
  submatrix((0, 0), (2, 4), delim: #(none, "}"),
    xshift: #3.5mm, reserve: #false),
  submatrix((3, 0), (4, 4), delim: #(none, "}"),
    xshift: #3.5mm, reserve: #false)) $
```, note: [`\SubMatrix{.}{..}{..}{\rbrace}` is a sub-matrix with one delimiter. As in the manual, the result is disappointing: `hbrace` / `vbrace` are better for this.])

#ex("L7027", ```
#nicemat-group[
  #let st = nicemat.with(align: right,
    last-col: true, vlines: 4,
    cell-space: (top: 1mm),
    map-cells: (i, j, it) => if j == 5 {
      text(blue, $script(it)$) } else { it })
  $ st(12, -8, 7, 5, 3, ;
    3, -18, 12, 1, 4, ;
    -3, -46, 29, -2, -15, ;
    9, 10, -5, 4, 7, ) $
  $ st(12, -8, 7, 5, 3, ;
    0, 64, -41, 1, 19, L_2 <- L_1 - 4 L_2;
    0, -192, 123, -3, -57, L_3 <- L_1 + 4 L_3;
    0, -64, 41, -1, -19, L_4 <- 3 L_1 - 4 L_4) $
  $ st(12, -8, 7, 5, 3, ;
    0, 64, -41, 1, 19, ;
    0, 0, 0, 0, 0, L_3 <- 3 L_2 + L_3) $
  $ st(12, -8, 7, 5, 3, ;
    0, 64, -41, 1, 19, ) $
]
```, also: ("L7125",), note: [Stacks of matrices. `nicemat-group` shares the widths of the columns and of the delimiters, so `delimiters/max-width` (p. 83) is not needed.])

#ex("L7202", ```
#set text(size: 9.5pt)
$ nicemat(delim: #none, align: #right,
  last-col: #true, cell-space: #(top: 1mm),
  row-gap: #range(12).map(k =>
    if k in (3, 7, 10) { 0.2em + 1mm } else { 0.2em }),
  map-cells: #((i, j, it) => if j == 5 {
    text(blue, $script(#it)$) } else { it }),
  12, -8, 7, 5, 3, ;
  3, -18, 12, 1, 4, ;
  -3, -46, 29, -2, -15, ;
  9, 10, -5, 4, 7, ;
  12, -8, 7, 5, 3, ;
  0, 64, -41, 1, 19, L_2 <- L_1 - 4 L_2;
  0, -192, 123, -3, -57, L_3 <- L_1 + 4 L_3;
  0, -64, 41, -1, -19, L_4 <- 3 L_1 - 4 L_4;
  12, -8, 7, 5, 3, ;
  0, 64, -41, 1, 19, ;
  0, 0, 0, 0, 0, L_3 <- 3 L_2 + L_3;
  12, -8, 7, 5, 3, ;
  0, 64, -41, 1, 19, ,
  submatrix((0, 0), (3, 4), vlines: 4),
  submatrix((4, 0), (7, 4), vlines: 4),
  submatrix((8, 0), (10, 4), vlines: 4),
  submatrix((11, 0), (12, 4), vlines: 4)) $
```, also: ("L7241",), note: [One matrix with four sub-matrices; `sub-matrix/vlines` and `vlines-in-sub-matrix` (p. 84) are the `vlines` of each sub-matrix.])

#ex("L7287", ```
$ nicemat(margin: #(x: 5pt), stroke: #blue,
  cell(a_11, stroke: #true), a_12, a_13, a_14;
  a_21, cell(a_22, stroke: #true), a_23, a_24;
  a_31, a_32, cell(a_33, stroke: #true), a_34;
  a_41, a_42, a_43, cell(a_44, stroke: #true)) $
```, note: [How to highlight cells. `stroke: #true` uses the stroke of the rules.])

#ex("L7314", ```
$ nicemat(margin: #(x: 7pt),
  fill: #((i, j) => if j >= i { red.lighten(85%) }),
  A_11, A_12, A_13, A_14;
  A_21, A_22, A_23, A_24;
  A_31, A_32, A_33, A_34;
  A_41, A_42, A_43, A_44) $
```)

#ex("L7333", ```
#let onerow(i) = region(row: i,
  outset: (x: -2.5pt, y: -0.8pt),
  fill: red.lighten(85%), radius: 2pt)
$ nicemat(last-col: #true, margin: #(x: 2pt),
  a, a + b, a + b + c, L_1;
  a, a, a + b, L_2;
  a, a, a, L_3,
  onerow(0), onerow(1), onerow(2)) $
```, note: [A block with TikZ offsets is a `region` with a negative `outset`; `row: i` covers the row inside the delimiters.])

#ex("L7383", ```
#set text(size: 9pt)
#let hl(from, to) = region(from, to, fit: "content",
  outset: 1pt, radius: 0.5mm, fill: red.lighten(85%))
$ nicearray(dots: #(nullify: true),
  column-gap: #range(10).map(k =>
    if k == 5 { 6mm } else { 0.5em }),
  row-gap: #range(10).map(k =>
    if k == 5 { 0.2em + 3mm } else { 0.2em }),
  map-cells: #((i, j, it) => if (i, j) in ((0, 8), (8, 0)) {
    text(blue, $script(#it)$) } else { it }),
  , , , , , , , , C_j;
  , , , , , , b_11, dots.c, b_(1 j), dots.c, b_(1 n);
  , , , , , , dots.v, , dots.v, , dots.v;
  , , , , , , , , b_(k j);
  , , , , , , , , dots.v;
  , , , , , , b_(n 1), dots.c, b_(n j), dots.c, b_(n n);
  , a_11, dots.c, , , a_(1 n);
  , dots.v, , , , dots.v, , , dots.v;
  L_i, a_(i 1), dots.c, a_(i k), dots.c, a_(i n),
    dots.c, , c_(i j);
  , dots.v, , , , dots.v;
  , a_(n 1), dots.c, , , a_(n n),
  submatrix((1, 6), (5, 10)),
  submatrix((6, 1), (10, 5)),
  submatrix((6, 6), (10, 10)),
  hl((8, 1), (8, 5)), hl((1, 8), (5, 8)),
  dotline((8, 3), (3, 8), bend: 30,
    stroke: #gray, shorten: #1mm)) $
```, also: ("L7371",), note: [The sub-matrices stop the leaders (like `\SubMatrix` in the `\CodeBefore`); the highlights are regions fitted to the contents; the curve is a bent `dotline` (`to [bend left]`).])

== Examples not ported

#context {
  let done = ported.final()
  let rest = latex.pairs().filter(((id, s)) => id not in done)
  let explicit = (
    L6967: [calligraphic braces (TikZ decoration); the braces of the math font are shown for p. 79],
  )
  let reason(id, code) = {
    if id in explicit { explicit.at(id) }
    else if code.contains("Tabular") or code.contains("tabular") { [text table (`{NiceTabular}`, `{tabular}`)] }
    else if code.contains("decoration") or code.contains("random steps") { [TikZ decoration] }
    else if code.contains("varwidth") or code.contains("minipage") { [text layout] }
    else if code.contains("ExplSyntaxOn") or code.contains("DeclareKeys") or code.contains("pgfset") or code.contains("usepackage") or code.contains("documentclass") { [LaTeX configuration] }
    else if code.contains("notes") { [notes of tabulars] }
    else if code.contains("CodeBefore [") or code.contains("\\textsl") { [syntax summary] }
    else { [—] }
  }
  [#rest.len() of the #latex.len() examples of the manual are not ported:]
  table(
    columns: (auto, auto, 1fr, auto),
    stroke: (x, y) => if y == 0 { (bottom: 0.6pt) } else { (bottom: 0.3pt + luma(220)) },
    inset: (x: 4pt, y: 3pt),
    table.header([*line*], [*page*], [*beginning of the code*], [*reason*]),
    ..rest.map(((id, s)) => (
      text(size: 8pt, id),
      text(size: 8pt, if s.page == none { "—" } else { str(s.page) }),
      text(size: 7pt, raw({
        let first = s.code.split("\n").filter(l => l.trim() != "").at(0, default: "").trim()
        let cs = first.clusters()
        cs.slice(0, calc.min(cs.len(), 55)).join() + if cs.len() > 55 { "…" } else { "" }
      })),
      text(size: 8pt, reason(id, s.code)),
    )).flatten(),
  )
}
