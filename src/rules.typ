/// Rules (`hlines`, `vlines`, `augment`, `hline()`, `vline()`) and the empty
/// corners.
///
/// A rule is cut into one segment per cell boundary; a segment is skipped
/// inside blocks (spanning cells, leaders), in empty corners and in the
/// exterior rows and columns, then consecutive segments are merged.

#import "util.typ": to-int, to-int-list, norm-index, merge-stroke, stroke-thickness, to-coord

/// Indices of the lines requested by a `hlines` / `vlines` style option.
/// `n` is the number of rows (or columns), `(m0, m1)` the range of lines
/// for `true` and `borders` whether the outer lines are included.
#let line-indices(spec, n, m0, m1, borders) = {
  if spec == none or spec == false { return () }
  if spec == true {
    let ks = range(m0 + 1, m1)
    if borders { ks = (m0,) + ks + (m1,) }
    return ks
  }
  to-int-list(spec, name: "lines").map(k => norm-index(k, n))
}

/// Cells belonging to the empty corners. Returns a 2D array of booleans.
///
/// `spec` is `true` (the four corners) or an alignment or an array of
/// alignments: `top + left` … and `top`, `bottom`, `left`, `right` for the
/// generalized corners of nicematrix 7.10 (N, S, W, E).
#let corner-cells(spec, R, C, r0, r1, c0, c1, empty) = {
  let res = range(R).map(_ => (false,) * C)
  if spec == none or spec == false { return res }
  let specs = if spec == true { (top + left, top + right, bottom + left, bottom + right) } else if type(spec) == array { spec } else { (spec,) }
  let rows-td(dir) = if dir == top { range(r0, r1) } else { range(r0, r1).rev() }
  let cols-lr(dir) = if dir == left { range(c0, c1) } else { range(c0, c1).rev() }
  for s in specs {
    let (vy, hx) = (s.y, s.x)
    if vy != none and hx != none {
      // A diagonal corner: union of the empty rectangles at that corner.
      let lim = c1 - c0
      for i in rows-td(vy) {
        let run = 0
        for j in cols-lr(hx) { if empty(i, j) { run += 1 } else { break } }
        lim = calc.min(lim, run)
        if lim == 0 { break }
        for (k, j) in cols-lr(hx).enumerate() { if k < lim { res.at(i).at(j) = true } }
      }
    } else if vy != none {
      for j in range(c0, c1) {
        for i in rows-td(vy) { if empty(i, j) { res.at(i).at(j) = true } else { break } }
      }
    } else if hx != none {
      for i in range(r0, r1) {
        for j in cols-lr(hx) { if empty(i, j) { res.at(i).at(j) = true } else { break } }
      }
    }
  }
  res
}

/// Computes rule items.
///
/// `specs`: array of `(dir: "h" | "v", k, start, end, stroke, marker: bool)`
/// where `k` is the line index (a line `k` separates rows/columns `k - 1`
/// and `k`) and `[start, end)` the range of columns/rows it covers.
/// `ctx`: `(R, C, r0, r1, c0, c1, own, cells, blocks, corner, rows, cols,
/// rtiles, ctiles, main, sep)`.
#let rule-items(specs, ctx) = {
  let items = ()
  // Lines requested through markers replace the option lines at the same
  // position (so that `hlines: true` plus two `hline()` gives a double rule).
  let with-marker = specs.filter(s => s.marker).map(s => s.dir + str(s.k))
  let specs = specs.filter(s => s.marker or (s.dir + str(s.k)) not in with-marker)

  let blocked(dir, k, t, leaders: true) = {
    // (a, b): the cells on both sides of the boundary at position t.
    let (a, b) = if dir == "h" { ((k - 1, t), (k, t)) } else { ((t, k - 1), (t, k)) }
    let (lo, hi) = if dir == "h" { (ctx.r0, ctx.r1) } else { (ctx.c0, ctx.c1) }
    let (t-min, t-max) = if dir == "h" { (ctx.c0, ctx.c1) } else { (ctx.r0, ctx.r1) }
    if t < t-min or t >= t-max or k < lo or k > hi { return true }
    let a-in = k - 1 >= lo
    let b-in = k < hi
    let own(p) = ctx.own.at(p.at(0)).at(p.at(1))
    if a-in and b-in {
      let (ca, cb) = (own(a), own(b))
      if ca == cb and not ctx.cells.at(ca).opts.at("transparent", default: false) { return true }
      for blk in if leaders { ctx.blocks } else { () } {
        let inb(p) = blk.i0 <= p.at(0) and p.at(0) <= blk.i1 and blk.j0 <= p.at(1) and p.at(1) <= blk.j1
        if inb(a) and inb(b) { return true }
      }
    }
    let corner(p) = ctx.corner.at(p.at(0)).at(p.at(1))
    let sides = ()
    if a-in { sides.push(corner(a)) }
    if b-in { sides.push(corner(b)) }
    sides.len() > 0 and sides.all(x => x)
  }

  let pos-of(dir, k) = {
    if dir == "h" {
      if k <= ctx.r0 { ctx.main.top } else if k >= ctx.r1 { ctx.main.bottom } else {
        (ctx.rows.at(k - 1).bottom + ctx.rows.at(k).top) / 2
      }
    } else {
      if k <= ctx.c0 { ctx.main.left } else if k >= ctx.c1 { ctx.main.right } else {
        ctx.ctiles.at(k).left
      }
    }
  }

  // Rank of each spec among the overlapping specs of the same line, for
  // double rules.
  let overlap(a, b) = a.dir == b.dir and a.k == b.k and a.start < b.end and b.start < a.end
  for (idx, s) in specs.enumerate() {
    if s.stroke == none { continue }
    let rank = specs.slice(0, idx).filter(o => overlap(o, s)).len()
    let n = specs.filter(o => overlap(o, s)).len()
    let th = stroke-thickness(s.stroke)
    let offset = (rank - (n - 1) / 2) * (th + ctx.sep)
    let base = pos-of(s.dir, s.k) + offset

    // Runs of drawable segments.
    let runs = ()
    let cur = none
    for t in range(s.start, s.end) {
      // `augment` lines come from `mat` and ignore the leaders.
      if blocked(s.dir, s.k, t, leaders: not s.at("augment", default: false)) {
        if cur != none { runs.push(cur); cur = none }
      } else {
        cur = if cur == none { (t, t) } else { (cur.at(0), t) }
      }
    }
    if cur != none { runs.push(cur) }

    for (t0, t1) in runs {
      if s.dir == "h" {
        let (x0, x1) = (ctx.ctiles.at(t0).left, ctx.ctiles.at(t1).right)
        items.push((x: x0, y: base, body: line(start: (0pt, 0pt), end: (x1 - x0, 0pt), stroke: s.stroke)))
      } else {
        let (y0, y1) = (ctx.rtiles.at(t0).top, ctx.rtiles.at(t1).bottom)
        items.push((x: base, y: y0, body: line(start: (0pt, 0pt), end: (0pt, y1 - y0), stroke: s.stroke)))
      }
    }
  }
  items
}
