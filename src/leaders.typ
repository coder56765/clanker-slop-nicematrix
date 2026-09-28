/// Dotted leaders: a port of the algorithm of nicematrix.
///
/// From the cell holding a leader, we walk in both directions through empty
/// cells until a non-empty cell (a "closed" extremity) or the border of the
/// matrix / an already dotted cell (an "open" extremity). Empty cells met on
/// the way are marked as dotted, so consecutive leaders give one line.
/// Leaders with `span` (like `\Hdotsfor`) only look at their neighbours.

#import "util.typ": abs-len, to-bool, merge-stroke
#import "draw.typ": leader-items

/// Direction steps.
#let _steps = (l: (0, 1), c: (0, 1), v: (1, 0), d: (1, 1), i: (1, -1))

/// Options that `connect` adds to those of `dotline`.
#let connect-preset = (stroke: (:), marks: "->", shorten: 0.2em)

/// Resolves the drawing style of a leader from the global `dots` options and
/// the options of the marker. `at` is the cell `(i, j)` where the leader
/// starts, given to a `fill` function. Must be called in a context.
#let leader-style(dots, opts, at: none) = {
  let o = dots + opts
  // `fill: (i, j) => color`, `none` meaning the text colour.
  let fill = if type(o.fill) == function {
    let f = if at == none { auto } else { (o.fill)(..at) }
    if f == none { auto } else { f }
  } else { o.fill }
  let fill = if fill == auto { text.fill } else { fill }
  let label-fill = if o.label-fill == auto {
    if page.fill == auto or page.fill == none { white } else { page.fill }
  } else { o.label-fill }
  let stroke = if o.stroke == auto { auto } else {
    merge-stroke((paint: fill, thickness: 0.05em.to-absolute(), cap: "round"), o.stroke)
  }
  (
    fill: fill,
    stroke: stroke,
    radius: abs-len(o.radius),
    spacing: abs-len(o.spacing),
    shorten: abs-len(o.shorten),
    shorten-start: if o.shorten-start == auto { auto } else { abs-len(o.shorten-start) },
    shorten-end: if o.shorten-end == auto { auto } else { abs-len(o.shorten-end) },
    marks: o.marks,
    mark-size: abs-len(o.mark-size),
    horizontal-labels: to-bool(o.horizontal-labels, name: "horizontal-labels"),
    label-fill: label-fill,
    above: o.at("above", default: none),
    below: o.at("below", default: none),
    middle: o.at("middle", default: none),
    explicit-shorten: "shorten" in opts or "shorten-start" in opts or "shorten-end" in opts,
    first: to-bool(o.at("first", default: false), name: "first"),
  )
}

/// Shortening of the two extremities: global shortening only applies to
/// closed extremities, a shortening given to the leader itself applies to
/// both (as in nicematrix).
#let _shorten(st, open0, open1) = {
  let s0 = if st.shorten-start == auto { st.shorten } else { st.shorten-start }
  let s1 = if st.shorten-end == auto { st.shorten } else { st.shorten-end }
  if not st.explicit-shorten {
    if open0 { s0 = 0pt }
    if open1 { s1 = 0pt }
  }
  st + (shorten-start: s0, shorten-end: s1)
}

/// Computes all leaders.
///
/// - `g`: the grid with positioned records (`box`, `base`),
/// - `geo`: `(rows, cols, R, C, r0, r1, c0, c1)`,
/// - `bounds-of`: function `(i, j) => (rmin, rmax, cmin, cmax)` giving the
///   region in which the leader starting at `(i, j)` may extend,
/// - `dots`: global leader options, `mets`: font metrics.
///
/// Returns `(items, bounds, blocks, lines)`; `blocks` are rectangles of
/// cells `(i0, j0, i1, j1)` in which rules must not be drawn, `lines` the raw
/// geometry for tests.
#let resolve-leaders(g, geo, bounds-of, dots, mets) = {
  let (R, C) = (geo.R, geo.C)
  let rows = geo.rows
  let cols = geo.cols
  let at(i, j) = g.cells.at(g.own.at(i).at(j))
  // Cells that stop a leader: non-empty contents (a block counts as a whole).
  let full(i, j) = {
    let c = at(i, j)
    c.kind in ("brace", "diagbox") or (c.kind == "cell" and not c.m.empty)
  }
  let dotted = range(R).map(_ => (false,) * C)

  // Open extremities use the extreme ink of the whole row / column.
  let col-cells(j) = range(R).filter(i => full(i, j) and at(i, j).colspan == 1).map(i => at(i, j))
  let row-cells(i) = range(C).filter(j => full(i, j) and at(i, j).rowspan == 1).map(j => at(i, j))
  let open-x0(j) = { let cs = col-cells(j); if cs.len() == 0 { cols.at(j).left } else { calc.min(..cs.map(c => c.box.x0)) } }
  let open-x1(j) = { let cs = col-cells(j); if cs.len() == 0 { cols.at(j).right } else { calc.max(..cs.map(c => c.box.x1)) } }
  let open-y0(i) = { let cs = row-cells(i); if cs.len() == 0 { rows.at(i).top } else { calc.min(..cs.map(c => c.box.y0)) } }
  let open-y1(i) = { let cs = row-cells(i); if cs.len() == 0 { rows.at(i).bottom } else { calc.max(..cs.map(c => c.box.y1)) } }
  let cx(c) = (c.box.x0 + c.box.x1) / 2

  // Order: spans first, then V, D, Id, C, L (as nicematrix); within a kind,
  // leaders marked `first` come first, then reading order.
  let leaders = g.cells.filter(c => c.kind == "leader")
  let order = ()
  for kind in ("span", "v", "d", "i", "c", "l") {
    let is-for(c) = c.rowspan > 1 or c.colspan > 1 or c.at("dotsfor", default: false)
    let ls = leaders.filter(c => if kind == "span" { is-for(c) } else { c.dir == kind and not is-for(c) })
    let firsts = ls.filter(c => to-bool(c.opts.at("first", default: false), name: "first"))
    order += firsts + ls.filter(c => not to-bool(c.opts.at("first", default: false), name: "first"))
  }

  let items = ()
  let bnds = ()
  let blocks = ()
  let lines = ()
  let slopes = (d: none, i: none)

  for L in order {
    if dotted.at(L.i).at(L.j) { continue }
    let (di, dj) = _steps.at(L.dir)
    let (rmin, rmax, cmin, cmax) = bounds-of(L.i, L.j)
    let inside(i, j) = i >= rmin and i <= rmax and j >= cmin and j <= cmax
    let (ini, fin) = ((L.i, L.j), (L.i + L.rowspan - 1, L.j + L.colspan - 1))
    let (open0, open1) = (true, true)

    for ii in range(L.i, L.i + L.rowspan) {
      for jj in range(L.j, L.j + L.colspan) { dotted.at(ii).at(jj) = true }
    }

    if L.rowspan > 1 or L.colspan > 1 or L.at("dotsfor", default: false) {
      // `\Hdotsfor` / `\Vdotsfor`: only the immediate neighbours matter.
      let (a, b) = ((ini.at(0) - di, ini.at(1) - dj), (fin.at(0) + di, fin.at(1) + dj))
      if inside(..a) and full(..a) { ini = a; open0 = false }
      if inside(..b) and full(..b) { fin = b; open1 = false }
    } else {
      // Walk backwards, then forwards.
      for (sign, which) in ((-1, 0), (1, 1)) {
        let (i, j) = if which == 0 { ini } else { fin }
        let open = true
        while true {
          let (ni, nj) = (i + sign * di, j + sign * dj)
          if not inside(ni, nj) or dotted.at(ni).at(nj) { break }
          if full(ni, nj) { (i, j) = (ni, nj); open = false; break }
          dotted.at(ni).at(nj) = true
          (i, j) = (ni, nj)
        }
        if which == 0 { ini = (i, j); open0 = open } else { fin = (i, j); open1 = open }
      }
    }

    let (ci, cf) = (at(..ini), at(..fin))
    let (p0, p1) = (none, none)
    if L.dir == "l" or L.dir == "c" {
      let y-of(c) = if L.dir == "l" { c.base } else { c.base - mets.cell-axis }
      let x0 = if open0 { open-x0(ini.at(1)) } else { ci.box.x1 }
      let x1 = if open1 { open-x1(fin.at(1)) } else { cf.box.x0 }
      let row-y = if L.dir == "l" { rows.at(L.i).base } else { rows.at(L.i).base - mets.cell-axis }
      let y0 = if open0 { if open1 { row-y } else { y-of(cf) } } else { y-of(ci) }
      let y1 = if open1 { if open0 { row-y } else { y-of(ci) } } else { y-of(cf) }
      if L.dir == "l" {
        let r = abs-len((dots + L.opts).radius)
        (y0, y1) = (y0 - r, y1 - r)
      }
      (p0, p1) = ((x0, y0), (x1, y1))
    } else if L.dir == "v" {
      let (x, y0, y1) = (none, none, none)
      if open0 and open1 {
        y0 = open-y0(ini.at(0))
        y1 = open-y1(fin.at(0))
        x = (cols.at(L.j).left + cols.at(L.j).right) / 2
      } else if open0 {
        y0 = open-y0(ini.at(0))
        y1 = cf.box.y0
        x = cx(cf)
      } else {
        y0 = ci.box.y1
        x = cx(ci)
        if open1 { y1 = open-y1(fin.at(0)) } else {
          y1 = cf.box.y0
          let xf = cx(cf)
          if xf != x {
            // Left-aligned column: keep the leftmost position, else the rightmost.
            x = if ci.box.x0 == cf.box.x0 { calc.min(x, xf) } else { calc.max(x, xf) }
          }
        }
      }
      (p0, p1) = ((x, y0), (x, y1))
    } else if L.dir == "d" {
      p0 = if open0 { (open-x0(ini.at(1)), open-y0(ini.at(0))) } else { (ci.box.x1, ci.box.y1) }
      p1 = if open1 { (open-x1(fin.at(1)), open-y1(fin.at(0))) } else { (cf.box.x0, cf.box.y0) }
    } else {
      // Iddots: `ini` is the upper-right extremity, `fin` the lower-left one.
      p0 = if open0 { (open-x1(ini.at(1)), open-y0(ini.at(0))) } else { (ci.box.x0, ci.box.y1) }
      p1 = if open1 { (open-x0(fin.at(1)), open-y1(fin.at(0))) } else { (cf.box.x1, cf.box.y0) }
    }

    let st = leader-style(dots, L.opts, at: (L.i, L.j))
    // Diagonals are drawn parallel to the first one.
    if L.dir in ("d", "i") and to-bool(dots.parallel, name: "parallel") and L.rowspan == 1 {
      let (dx, dy) = (p1.at(0) - p0.at(0), p1.at(1) - p0.at(1))
      if slopes.at(L.dir) == none {
        if dx != 0pt { slopes.insert(L.dir, dy / dx) }
      } else {
        p1 = (p1.at(0), p0.at(1) + dx * slopes.at(L.dir))
      }
    }

    let r = leader-items(p0, p1, _shorten(st, open0, open1))
    items += r.items
    bnds += r.bounds
    blocks.push((
      i0: calc.min(ini.at(0), fin.at(0)), j0: calc.min(ini.at(1), fin.at(1)),
      i1: calc.max(ini.at(0), fin.at(0)), j1: calc.max(ini.at(1), fin.at(1)),
    ))
    lines.push((dir: L.dir, from: ini, to: fin, open: (open0, open1), p0: p0, p1: p1))
  }
  (items: items, bounds: bnds, blocks: blocks, lines: lines)
}

/// A leader between two arbitrary cells (the `dotline` decoration): from the
/// centre of each content, a ray (turned by `bend` to the left of the way
/// from `a` to `b`, symmetrically at `b`) clipped by the content.
#let dotline-points(a, b, bend: 0deg) = {
  let ca = ((a.box.x0 + a.box.x1) / 2, (a.box.y0 + a.box.y1) / 2)
  let cb = ((b.box.x0 + b.box.x1) / 2, (b.box.y0 + b.box.y1) / 2)
  let (dx, dy) = (cb.at(0) - ca.at(0), cb.at(1) - ca.at(1))
  let l = calc.sqrt(calc.pow(dx / 1pt, 2) + calc.pow(dy / 1pt, 2)) * 1pt
  if l == 0pt { return (ca, cb) }
  let (ux, uy) = (dx / l, dy / l)
  // The left of the direction of travel, on the page (y grows downwards).
  let (nx, ny) = (uy, -ux)
  let (co, si) = (calc.cos(bend), calc.sin(bend))
  let out = (ux * co + nx * si, uy * co + ny * si)
  let inn = (-ux * co + nx * si, -uy * co + ny * si)
  let exit(c, v) = {
    let (hw, hh) = ((c.box.x1 - c.box.x0) / 2, (c.box.y1 - c.box.y0) / 2)
    let tx = if calc.abs(v.at(0)) < 1e-9 { 1e9 * 1pt } else { hw / calc.abs(v.at(0)) }
    let ty = if calc.abs(v.at(1)) < 1e-9 { 1e9 * 1pt } else { hh / calc.abs(v.at(1)) }
    calc.min(tx, ty)
  }
  let (ta, tb) = (exit(a, out), exit(b, inn))
  (
    (ca.at(0) + out.at(0) * ta, ca.at(1) + out.at(1) * ta),
    (cb.at(0) + inn.at(0) * tb, cb.at(1) + inn.at(1) * tb),
  )
}
