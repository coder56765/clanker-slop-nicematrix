// Unit tests of the helpers and of the resolution of leaders.
#import "/nicematrix.typ": *

#set page(width: auto, height: auto, margin: 1em)

// --- Coercions of math-mode values.
#let args(..a) = a
#let math-args(eq) = eq.body.value
#let grab(..a) = metadata(a)

#assert.eq(_to-int($3$.body), 3)
#assert.eq(_to-int($−2$.body), -2)
#assert.eq(_to-int("7"), 7)
#assert.eq(_to-coord((1, 2)), (1, 2))
#assert.eq(_to-coord("1-2"), (1, 2))
#assert.eq(_to-coord("(0, −1)"), (0, -1))
#assert.eq(_to-coord((row: 2, col: 3)), (2, 3))
#let math-coords = $grab((0, 1), (2, −1))$.body.value.pos()
#assert.eq(_to-coord(math-coords.at(0)), (0, 1))
#assert.eq(_to-coord(math-coords.at(1)), (2, -1))
#assert.eq(_norm-index(-1, 5), 4)
#assert.eq(_delim-pair("("), ("(", ")"))
#assert.eq(_delim-pair("[").at(1), "]")
#assert.eq(_delim-pair(("[", ")")), ("[", ")"))
#assert.eq(_delim-pair(none), (none, none))
#assert.eq(_merge-stroke((thickness: 1pt), red), (thickness: 1pt, paint: red))
#assert.eq(_merge-stroke((thickness: 1pt), (dash: "dashed")), (thickness: 1pt, dash: "dashed"))

// --- Leader detection.
#assert.eq(_auto-leader(sym.dots.c), "c")
#assert.eq(_auto-leader(sym.dots.h), "l")
#assert.eq(_auto-leader([⋮]), "v")
#assert.eq(_auto-leader($dots.down$.body), "d")
#assert.eq(_auto-leader(sym.dots.up), "i")
#assert.eq(_auto-leader(cdots), "c")
#assert.eq(_auto-leader($x$.body), none)
#assert.eq(_marker-of(cdots(span: 2)).dir, "c")

// --- Parsing: spans skip covered positions, markers are extracted.
#let parse(eq) = _parse-body(_rows-of(eq.body.value.pos()))
#let g = parse($grab(cell(A, rowspan: 2, colspan: 2), 0; 0; hline(); 1, 2, 3, vline(); submatrix((0, 0), (1, 1)))$)
#assert.eq((g.nrows, g.ncols), (3, 3))
#assert.eq(g.own.at(0), (0, 0, 1))
#assert.eq(g.own.at(1), (0, 0, 2))
#assert.eq(g.hlines.map(h => h.pos), (2,))
#assert.eq(g.vlines.map(v => v.pos), (3,))
#assert.eq(g.decos.len(), 1)
#let g = parse($grab(1, cdots(span: 3), 5; a)$)
#assert.eq(g.cells.at(1).colspan, 3)
#assert.eq(g.cells.at(2).j, 4)
#assert.eq((g.nrows, g.ncols), (2, 5))
#let g = parse($grab(1, 2; 3)$)
#assert.eq(g.cells.last().kind, "pad")

// --- Leaders: extremities found like nicematrix.
#let check-leaders(name, m, expected) = {
  let st = state("leaders-" + name)
  box(m.with(foreground: g => { st.update(g.leaders); none })())
  context {
    let got = st.final().map(l => (l.dir, l.from, l.to, l.open))
    assert.eq(got, expected, message: name)
  }
}
#check-leaders("null matrix",
  nicemat.with(($0$, $dots.c$, $0$), ($dots.v$, [], $dots.v$), ($0$, $dots.c$, $0$)),
  (("v", (0, 0), (2, 0), (false, false)), ("v", (0, 2), (2, 2), (false, false)),
   ("c", (0, 0), (0, 2), (false, false)), ("c", (2, 0), (2, 2), (false, false))))
#check-leaders("merged runs",
  nicemat.with(($0$, $dots.c$, $dots.c$, $0$), ($dots.v$, [], [], $dots.v$), ($dots.v$, [], [], $dots.v$), ($0$, $dots.c$, $dots.c$, $0$)),
  (("v", (0, 0), (3, 0), (false, false)), ("v", (0, 3), (3, 3), (false, false)),
   ("c", (0, 0), (0, 3), (false, false)), ("c", (3, 0), (3, 3), (false, false))))
#check-leaders("open ends",
  nicemat.with(($dots.c$, $a$), ($b$, $dots.v$)),
  (("v", (0, 1), (1, 1), (false, true)), ("c", (0, 0), (0, 1), (true, false))))
#check-leaders("hdotsfor open",
  nicemat.with(($1$, $2$, $3$), ([], cdots(span: 2)), ($1$, $2$, $3$)),
  (("c", (1, 1), (1, 2), (true, true)),))
#check-leaders("hdotsfor closed",
  nicemat.with(($1$, $2$, $3$, $4$), ($1$, cdots(span: 2), $4$)),
  (("c", (1, 0), (1, 3), (false, false)),))
#check-leaders("submatrix bound",
  nicemat.with(($a$, $dots.c$, [], $b$), ($c$, [], [], $d$), submatrix((0, 0), (1, 1))),
  (("c", (0, 0), (0, 1), (false, true)),))



// Lists of integers written in math mode.
#assert.eq(_to-int-list($grab((1, −1))$.body.value.pos().at(0)), (1, -1))
#assert.eq(_to-int-list($3$.body), (3,))
#assert.eq(_to-int-list((1, 2)), (1, 2))


// Strokes given as `stroke` values (e.g. `red + 2pt`).
#assert.eq(_merge-stroke((thickness: 1pt, dash: "dashed"), red + 2pt), (thickness: 2pt, dash: "dashed", paint: red))

// Angles.
#assert.eq(_to-angle(30), 30deg)
#assert.eq(_to-angle($−45$.body), -45deg)
#assert.eq(_to-angle(0.5rad), 0.5rad)

// --- Markers carry a fallback shown outside `nicemat`, and are still found.
#assert.eq(cdots().children.len(), 2)
#assert.eq(_marker-of(cdots()).dir, "c")
#assert.eq(_marker-of(cell($a$, rowspan: 2)).nicematrix, "cell")
#assert.eq(_marker-of(diagbox($x$, $y$)).nicematrix, "diagbox")
#assert.eq(_marker-of(hbrace($A$, span: 2)).nicematrix, "brace")
#assert.eq(_marker-of(hline()).nicematrix, "hline")
#assert.eq(_marker-of($cdots() + x$.body), none)
#assert.eq(_marker-of($grab(cdots())$.body.value.pos().at(0)).dir, "c")
// `cell(diagbox(..))` is still a diagonal block.
#let g = parse($grab(cell(diagbox(x, y), rowspan: 2), 1; 2)$)
#assert.eq(g.cells.at(0).kind, "diagbox")

// --- Whole rows and columns.
#let rng(m) = _deco-range(_marker-of(m), 4, 5, main: (1, 4, 0, 4))
#assert.eq(rng(region((0, 1), (2, 3))), (i0: 0, j0: 1, i1: 2, j1: 3))
#assert.eq(rng(region(row: 2)), (i0: 2, j0: 0, i1: 2, j1: 3))
#assert.eq(rng(region(rows: (1, 2))), (i0: 1, j0: 0, i1: 2, j1: 3))
#assert.eq(rng(region(col: −1)), (i0: 1, j0: 4, i1: 3, j1: 4))
#assert.eq(rng(submatrix(cols: (0, 1))), (i0: 1, j0: 0, i1: 3, j1: 1))
#assert.eq(rng(region(rows: (0, 1), cols: (2, 3))), (i0: 0, j0: 2, i1: 1, j1: 3))
#assert.eq(rng(hbrace($A$, cols: (1, 2))), (i0: 1, j0: 1, i1: 3, j1: 2))
#assert.eq(_marker-of(vbrace($B$, rows: (0, 1))).label, $B$)
#assert.eq(rng($grab(region(rows: (1, 2)))$.body.value.pos().at(0)), (i0: 1, j0: 0, i1: 2, j1: 3))

// --- Borders of `hlines` / `vlines`.
#assert.eq(_line-indices(true, 3, 0, 3, false), (1, 2))
#assert.eq(_line-indices(true, 3, 0, 3, true), (0, 1, 2, 3))
#assert.eq(_line-indices((1,), 3, 0, 3, true), (1,))

// --- Multi-line cells are as tall as their lines.
#let size(m) = box(m)
#context {
  let one = measure(box($nicemat(a, b; c, d)$)).height
  let two = measure(box($nicemat(a \ b, b; c, d)$)).height
  let three = measure(box($nicemat(a \ b \ c, b; c, d)$)).height
  assert(two > one and three > two, message: "multi-line heights " + repr((one, two, three)))
  // A cell spanning two rows with two lines needs no more room than the rows.
  let span = measure(box($nicemat(cell(a \ b, rowspan: #2), x; y)$)).height
  assert(calc.abs(span - one) < 0.01pt, message: "multi-line block " + repr((span, one)))
}

// --- Named matrices.
$ nicemat(name: "U", 1, 2; 3, 4) quad nicemat(name: "V", a, b, c) $
#context {
  let c = nicemat-cell("U", (1, 1))
  let d = nicemat-cell("U", (0, 0))
  let e = nicemat-cell("V", (0, −1))
  if c != none {
    assert.eq(c.page, 1)
    assert(c.x > d.x and c.y > d.y, message: "cell positions " + repr((c, d)))
    assert(e.x > c.x, message: "second matrix on the right")
    assert(c.ink.width > 0pt and c.ink.x >= c.x and c.ink.x + c.ink.width <= c.x + c.width)
    [named matrices checked]
  }
  assert.eq(nicemat-cell("nothing", (0, 0)), none)
}
ok
