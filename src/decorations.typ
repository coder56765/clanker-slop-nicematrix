/// Decorations drawn over (or under) the laid-out matrix: sub-matrix
/// delimiters, braces, regions and free leaders. All functions must be
/// called in a context.

#import "util.typ": *
#import "metrics.typ": BIG, cell-eq, ink, placeable, delim-glyph
#import "draw.typ": label-box, leader-items
#import "leaders.typ": leader-style, dotline-points

/// Reads the corners of a decoration and orders them.
#let deco-range(d, R, C) = {
  let (i0, j0) = to-coord(d.from, name: "from")
  let (i1, j1) = to-coord(d.to, name: "to")
  let shown = "(" + str(i0) + ", " + str(j0) + ") to (" + str(i1) + ", " + str(j1) + ")"
  let (i0, i1) = (norm-index(i0, R), norm-index(i1, R))
  let (j0, j1) = (norm-index(j0, C), norm-index(j1, C))
  let (i0, i1) = (calc.min(i0, i1), calc.max(i0, i1))
  let (j0, j1) = (calc.min(j0, j1), calc.max(j0, j1))
  if i0 < 0 or j0 < 0 or i1 >= R or j1 >= C {
    let kind = if d.nicematrix == "span-brace" { d.dir + "brace" } else { d.nicematrix }
    panic("nicematrix: `" + kind + "` " + shown + " is outside the " + str(R) + "×" + str(C)
      + " grid (rows and columns count from 0, as written)")
  }
  (i0: i0, j0: j0, i1: i1, j1: j1)
}

// --- Sub-matrices -----------------------------------------------------------

/// Prepares the sub-matrices once the rows are laid out: their delimiters
/// (whose width depends only on their height) and the room they need.
#let prepare-submatrices(decos, R, C, rows) = {
  let subs = ()
  let need-left = (:)
  let need-right = (:)
  for d in decos.filter(d => d.nicematrix == "submatrix") {
    let r = deco-range(d, R, C)
    let extra = abs-len(d.at("extra-height", default: 0pt))
    let (top, bottom) = (rows.at(r.i0).top - extra / 2, rows.at(r.i1).bottom + extra / 2)
    let (lp, rp) = delim-pair(d.at("delim", default: "("))
    let f = d.at("fill", default: auto)
    let xs = abs-len(d.at("xshift", default: 0pt))
    let lxs = abs-len(d.at("left-xshift", default: xs))
    let rxs = abs-len(d.at("right-xshift", default: xs))
    // Unlike those of the whole matrix (which follow `mat`), the delimiters of
    // a sub-matrix are as tall as its rows, as in nicematrix: stacked
    // sub-matrices must not overlap.
    let h = (bottom - top) / 1.1
    let lg = if lp == none { none } else { delim-glyph(lp, h, side: left, fill: f) }
    let rg = if rp == none { none } else {
      // `sup` / `sub` are attached to the right delimiter, like `\SubMatrix(..)^{T}`.
      delim-glyph(rp, h, side: right, fill: f, tr: d.at("sup", default: none), br: d.at("sub", default: none))
    }
    let reserve = to-bool(d.at("reserve", default: true), name: "reserve")
    if reserve {
      let wl = if lg == none { 0pt } else { lg.w } + calc.max(lxs, 0pt)
      let wr = if rg == none { 0pt } else { rg.w } + calc.max(rxs, 0pt)
      need-left.insert(str(r.j0), calc.max(need-left.at(str(r.j0), default: 0pt), wl))
      need-right.insert(str(r.j1), calc.max(need-right.at(str(r.j1), default: 0pt), wr))
    }
    subs.push(r + (
      spec: d, top: top, bottom: bottom, lg: lg, rg: rg, lxs: lxs, rxs: rxs,
      bound: to-bool(d.at("bound", default: true), name: "bound"),
      slim: to-bool(d.at("slim", default: false), name: "slim"),
    ))
  }
  (subs: subs, need-left: need-left, need-right: need-right)
}

/// Items of the sub-matrix delimiters. `x-extent(j, i0, i1)` gives the
/// horizontal ink extent of column `j` (restricted to rows `i0..i1` when
/// not `none`).
#let submatrix-items(subs, x-extent, axis) = {
  let items = ()
  let bounds = ()
  for s in subs {
    let cy = (s.top + s.bottom) / 2
    let base = cy + axis
    let rows = if s.slim { (s.i0, s.i1) } else { none }
    if s.lg != none {
      let x = x-extent(s.j0, rows).at(0) - s.lxs - s.lg.w
      items.push((x: x, y: base - BIG, body: placeable(s.lg.body)))
      bounds.push((x0: x, x1: x + s.lg.w, y0: base - s.lg.a, y1: base + s.lg.d))
    }
    if s.rg != none {
      let x = x-extent(s.j1, rows).at(1) + s.rxs
      items.push((x: x, y: base - BIG, body: placeable(s.rg.body)))
      bounds.push((x0: x, x1: x + s.rg.w, y0: base - s.rg.a, y1: base + s.rg.d))
    }
  }
  (items: items, bounds: bounds)
}

/// Rule specifications of the `hlines` / `vlines` options of sub-matrices
/// (line numbers relative to the sub-matrix).
#let submatrix-rules(subs, default-stroke) = {
  let specs = ()
  for s in subs {
    let st = merge-stroke(default-stroke, s.spec.at("stroke", default: auto))
    for (key, dir) in (("hlines", "h"), ("vlines", "v")) {
      let v = s.spec.at(key, default: none)
      let (n, k0) = if dir == "h" { (s.i1 - s.i0 + 1, s.i0) } else { (s.j1 - s.j0 + 1, s.j0) }
      let (t0, t1) = if dir == "h" { (s.j0, s.j1 + 1) } else { (s.i0, s.i1 + 1) }
      let ks = if v == none or v == false { () } else if v == true { range(1, n) } else {
        to-int-list(v, name: key).map(k => norm-index(k, n))
      }
      for k in ks { specs.push((dir: dir, k: k0 + k, start: t0, end: t1, stroke: st, marker: true)) }
    }
  }
  specs
}

// --- Braces ------------------------------------------------------------------

/// A horizontal brace of width `w` with its label; `over` puts the brace
/// above the baseline (label on top), otherwise below.
#let hbrace-eq(w, label, over: true, fill: auto) = {
  let b = box(width: w, height: 0pt)
  let e = math.equation(if over { math.overbrace(b, label) } else { math.underbrace(b, label) })
  if fill != auto and fill != none { e = text(fill: fill, e) }
  let m = ink(e)
  (body: e, w: m.w, a: m.a, d: m.d)
}

/// A vertical brace of height about `h` with its label; `right` puts the
/// brace on the right of the object (it opens to the left, label after).
/// Returns the pieces and the total width.
#let vbrace-eq(h, label, right: true, fill: auto) = {
  let h = calc.max(h, 1pt)
  let g = delim-glyph(if right { "}" } else { "{" }, h / 1.1, side: if right { right } else { left }, fill: fill)
  let lb = if label == none { none } else {
    let e = cell-eq(label, small: true)
    if fill != auto and fill != none { e = text(fill: fill, e) }
    let m = ink(e)
    (body: e, w: m.w, a: m.a, d: m.d)
  }
  let sep = 0.2em.to-absolute()
  let w = g.w + if lb == none { 0pt } else { sep + lb.w }
  (glyph: g, label: lb, sep: sep, w: w)
}

/// Items for a vertical brace placed with its glyph between `y0` and `y1`,
/// starting at `x` (the side facing the matrix).
#let vbrace-items(vb, x, y0, y1, right: true, axis: 0pt) = {
  let items = ()
  let bounds = ()
  let cy = (y0 + y1) / 2
  let g = vb.glyph
  let gx = if right { x } else { x - g.w }
  items.push((x: gx, y: cy + axis - BIG, body: placeable(g.body)))
  bounds.push((x0: gx, x1: gx + g.w, y0: cy + axis - g.a, y1: cy + axis + g.d))
  if vb.label != none {
    let lb = vb.label
    let lx = if right { x + g.w + vb.sep } else { x - g.w - vb.sep - lb.w }
    let base = cy + (lb.a - lb.d) / 2
    items.push((x: lx, y: base - BIG, body: placeable(lb.body)))
    bounds.push((x0: lx, x1: lx + lb.w, y0: base - lb.a, y1: base + lb.d))
  }
  (items: items, bounds: bounds)
}

/// Items for a horizontal brace from `x0` to `x1`, its box on the line `y`.
#let hbrace-items(x0, x1, y, label, over: true, fill: auto) = {
  let hb = hbrace-eq(x1 - x0, label, over: over, fill: fill)
  (
    items: ((x: x0, y: y - BIG, body: placeable(hb.body)),),
    bounds: ((x0: x0, x1: x0 + hb.w, y0: y - hb.a, y1: y + hb.d),),
  )
}

// --- Regions -----------------------------------------------------------------

/// Items of a `region` decoration: `rect` is the rectangle to cover.
#let region-item(d, r, default-stroke) = {
  let o = sides(d.at("outset", default: 0pt))
  let (o-l, o-r, o-t, o-b) = (abs-len(o.left), abs-len(o.right), abs-len(o.top), abs-len(o.bottom))
  let body = rect(
    width: r.x1 - r.x0 + o-l + o-r,
    height: r.y1 - r.y0 + o-t + o-b,
    fill: d.at("fill", default: none),
    stroke: {
      let s = d.at("stroke", default: none)
      if s == none { none } else { side-stroke(default-stroke, s) }
    },
    radius: d.at("radius", default: 0pt),
    inset: 0pt,
  )
  (x: r.x0 - o-l, y: r.y0 - o-t, body: body)
}
