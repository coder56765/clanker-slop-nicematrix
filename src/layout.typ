/// Row and column geometry.
///
/// Coordinates are in a local space where `y` grows downwards; the final
/// box is shifted so that everything is visible. Every row has a strut box
/// (`top`, `base`, `bottom`) at least as tall as a parenthesis, exactly like
/// Typst's `mat`, and a "tile" that extends to the middle of the gaps.

#import "util.typ": abs-len, pick

/// Vertical layout.
///
/// - `grid`: parse result whose records carry measurements in `m`
///   (`w`, `a`, `d`, `empty`).
/// - `o`: resolved options (`row-gap`, `cell-space`, `margin`, `r0`, `r1`).
#let layout-rows(grid, mets, o) = {
  let R = grid.nrows
  let asc = (mets.paren-a,) * R
  let desc = (mets.paren-d,) * R
  for c in grid.cells {
    if c.rowspan != 1 { continue }
    let (a, d) = (c.m.a, c.m.d)
    if not c.m.empty {
      a += o.cell-space.top
      d += o.cell-space.bottom
    }
    asc.at(c.i) = calc.max(asc.at(c.i), a)
    desc.at(c.i) = calc.max(desc.at(c.i), d)
  }

  let gaps = range(calc.max(R - 1, 0)).map(k => {
    let g = abs-len(pick(o.row-gap, k))
    if k == o.r0 - 1 { g += o.margin.top }
    if k == o.r1 - 1 { g += o.margin.bottom }
    g
  })
  let lead = if o.r0 == 0 { o.margin.top } else { 0pt }

  let place-rows(asc, desc) = {
    let rows = ()
    let y = lead
    for i in range(R) {
      let top = y
      let base = y + asc.at(i)
      let bottom = base + desc.at(i)
      rows.push((top: top, base: base, bottom: bottom))
      y = bottom + if i < R - 1 { gaps.at(i) } else { 0pt }
    }
    rows
  }
  let rows = place-rows(asc, desc)

  // Cells spanning several rows only grow the rows when they do not fit.
  let grew = false
  for c in grid.cells {
    if c.rowspan < 2 { continue }
    let last = c.i + c.rowspan - 1
    let avail = rows.at(last).bottom - rows.at(c.i).top
    let need = c.m.a + c.m.d
    if need > avail {
      desc.at(last) += need - avail
      grew = true
    }
  }
  if grew { rows = place-rows(asc, desc) }

  let main = (
    top: rows.at(o.r0).top - o.margin.top,
    bottom: rows.at(o.r1 - 1).bottom + o.margin.bottom,
  )
  let tiles = range(R).map(i => (
    top: if i == o.r0 { main.top } else if i == 0 { rows.at(0).top } else if i == o.r1 { rows.at(i).top } else {
      (rows.at(i - 1).bottom + rows.at(i).top) / 2
    },
    bottom: if i == o.r1 - 1 { main.bottom } else if i == R - 1 { rows.at(i).bottom } else if i == o.r0 - 1 { rows.at(i).bottom } else {
      (rows.at(i).bottom + rows.at(i + 1).top) / 2
    },
  ))
  (rows: rows, gaps: gaps, tiles: tiles, main: main)
}

/// Horizontal layout.
///
/// Extra options in `o`: `column-gap`, `column-width` (auto, a length or
/// `"equal"`), `group` (array of minimum widths for all columns, or none),
/// `c0`, `c1`, and `need-left` / `need-right`: dictionaries from column index
/// to extra room (for the delimiters of sub-matrices). `delim-w` is the
/// `(left, right)` width of the main delimiters.
#let layout-cols(grid, o) = {
  let C = grid.ncols
  let (c0, c1) = (o.c0, o.c1)
  let w = (0pt,) * C
  for c in grid.cells {
    if c.colspan == 1 { w.at(c.j) = calc.max(w.at(c.j), c.m.w) }
  }
  let cw = o.column-width
  if type(cw) == length or type(cw) == relative {
    let v = abs-len(cw)
    for j in range(c0, c1) { w.at(j) = calc.max(w.at(j), v) }
  } else if type(cw) == array {
    // One minimum width per column (as written), like `w{c}{1cm}`.
    for (j, v) in cw.enumerate() {
      if j < C and v != auto and v != none { w.at(j) = calc.max(w.at(j), abs-len(v)) }
    }
  }
  if o.group != none {
    for (k, v) in o.group.enumerate() {
      if k < C { w.at(k) = calc.max(w.at(k), v) }
    }
  }
  if cw == "equal" {
    let m = calc.max(0pt, ..w.slice(c0, c1))
    for j in range(c0, c1) { w.at(j) = m }
  }

  let need-l(j) = o.need-left.at(str(j), default: 0pt)
  let need-r(j) = o.need-right.at(str(j), default: 0pt)
  let base-gaps = range(calc.max(C - 1, 0)).map(k => abs-len(pick(o.column-gap, k)))
  let gaps = range(calc.max(C - 1, 0)).map(k => {
    let g = base-gaps.at(k)
    // Room for sub-matrix delimiters between two main columns.
    if k >= c0 and k + 1 < c1 {
      let extra = need-r(k) + need-l(k + 1)
      if extra > 0pt { g += extra }
    }
    g
  })

  // Columns spanning several columns only widen them when they overflow.
  for c in grid.cells {
    if c.colspan < 2 { continue }
    let js = range(c.j, c.j + c.colspan)
    let avail = js.map(j => w.at(j)).sum() + range(c.j, c.j + c.colspan - 1).map(k => gaps.at(k)).sum(default: 0pt)
    if c.m.w > avail {
      let extra = (c.m.w - avail) / c.colspan
      for j in js { w.at(j) += extra }
    }
  }

  let margin-l = o.margin.left + need-l(c0)
  let margin-r = o.margin.right + need-r(c1 - 1)
  let (dl, dr) = o.delim-w
  let cols = ()
  let x = 0pt
  for j in range(C) {
    if j == c0 { x += dl + margin-l }
    cols.push((left: x, right: x + w.at(j)))
    x += w.at(j)
    if j == c1 - 1 { x += margin-r + dr }
    if j < C - 1 { x += gaps.at(j) }
  }

  let main = (left: cols.at(c0).left - margin-l, right: cols.at(c1 - 1).right + margin-r)
  // Tiles meet in the middle of the ordinary gap: the room reserved for the
  // delimiters of sub-matrices stays on the side of their columns.
  let reserved(j, k) = if j >= c0 and j < c1 and k >= c0 and k < c1 { true } else { false }
  let tiles = range(C).map(j => (
    left: if j == c0 { main.left } else if j == 0 or j == c1 { cols.at(j).left } else {
      let extra = if reserved(j - 1, j) { need-l(j) } else { 0pt }
      cols.at(j).left - extra - base-gaps.at(j - 1) / 2
    },
    right: if j == c1 - 1 { main.right } else if j == C - 1 or j == c0 - 1 { cols.at(j).right } else {
      let extra = if reserved(j, j + 1) { need-r(j) } else { 0pt }
      cols.at(j).right + extra + base-gaps.at(j) / 2
    },
  ))
  (cols: cols, gaps: gaps, tiles: tiles, main: main, width: x)
}
