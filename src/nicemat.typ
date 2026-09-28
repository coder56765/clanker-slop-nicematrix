/// The `nicemat` function: argument resolution and the rendering pipeline
/// (parse → measure → layout → leaders → rules → decorations → box).

#import "util.typ": *
#import "parse.typ": rows-of, parse-body
#import "metrics.typ": BIG, cell-eq, ink, placeable, math-metrics, delim-glyph, math-level, math-style, style-at
#import "layout.typ": layout-rows, layout-cols
#import "leaders.typ": resolve-leaders, leader-style, dotline-points, connect-preset
#import "rules.typ": line-indices, corner-cells, rule-items
#import "decorations.typ": *
#import "group.typ": group-state, group-widths
#import "pave.typ": pave-segments, merge-segments, flood-cells

#let dots-defaults = (
  symbols: true,
  nullify: false,
  fill: auto,
  stroke: auto,
  radius: 0.53pt,
  spacing: 0.45em,
  shorten: 0.3em,
  shorten-start: auto,
  shorten-end: auto,
  parallel: true,
  horizontal-labels: false,
  marks: none,
  mark-size: 4pt,
  label-fill: auto,
)

/// Whether content is "empty" in the sense of nicematrix: nothing, spaces, or
/// only horizontal/vertical spacing (the analogue of `\Hspace`).
#let _content-empty(b) = {
  if b == none or b == [] { return true }
  let f = b.func()
  if f == [ ].func() or f == h or f == v { return true }
  if f == metadata { return true }
  if b.has("children") { return b.children.all(_content-empty) }
  false
}

/// The lines of a cell body written with `\` (one line: `none`).
#let _split-lines(b) = {
  if type(b) != content or not b.has("children") { return none }
  if not b.children.any(c => c.func() == linebreak) { return none }
  let lines = ((),)
  for c in b.children {
    if c.func() == linebreak { lines.push(()) } else { lines.at(-1).push(c) }
  }
  lines.map(l => if l.len() == 0 { [] } else { l.join() })
}

/// Measures a record in the math style `st` (from `math-style`). `lines`
/// holds what multi-line cells need: the horizontal alignment of each cell
/// and the gap between lines.
#let _measure-record(c, st, dots, lines) = {
  if c.kind == "cell" and "lines" in c {
    // Lines stacked like the rows of `mat` (a `vec` without delimiters,
    // whose cells keep the style of the cell), centred on the math axis.
    let ha = (lines.align)(c)
    let stack = math.vec(delim: none, align: ha, gap: lines.gap, ..c.lines.map(l => style-at(st.cells, l)))
    let e = cell-eq(stack, style: st)
    let m = ink(e)
    let forced = c.opts.at("empty", default: auto)
    let empty = if forced != auto { to-bool(forced, name: "empty") } else { c.lines.all(_content-empty) or m.w == 0pt }
    return c + (eq: e, m: m + (empty: empty))
  }
  if c.kind == "cell" or c.kind == "pad" {
    let e = cell-eq(c.body, style: st)
    let m = ink(e)
    let forced = c.opts.at("empty", default: auto)
    let empty = if forced != auto { to-bool(forced, name: "empty") } else { _content-empty(c.body) or m.w == 0pt }
    return c + (eq: e, m: m + (empty: empty))
  }
  if c.kind == "leader" {
    let nullify = to-bool(c.opts.at("nullify", default: dots.nullify), name: "nullify")
    let spanned = c.rowspan > 1 or c.colspan > 1 or c.at("dotsfor", default: false)
    let m = if nullify or spanned { (w: 0pt, a: 0pt, d: 0pt) } else { ink(cell-eq(c.body, style: st)) }
    return c + (eq: none, m: m + (empty: true))
  }
  if c.kind == "diagbox" {
    // Room for the two labels on both sides of the diagonal.
    let (lo, up) = (cell-eq(c.lower, style: st), cell-eq(c.upper, style: st))
    let (ml, mu) = (ink(lo), ink(up))
    let m = (w: ml.w + mu.w, a: mu.a + mu.d + ml.a, d: ml.d, empty: false)
    return c + (eq: none, lower-eq: lo, upper-eq: up, ml: ml, mu: mu, m: m)
  }
  // Braces are measured once the layout of the rest is known.
  c + (eq: none, m: (w: 0pt, a: 0pt, d: 0pt, empty: true))
}

/// Resolves a gap option: explicit value, then the value of a `mat` passed
/// in, then the `math.mat` set rules. Must be called in a context.
#let _gap(explicit, gap, from-mat, key) = {
  if explicit != auto { return explicit }
  if gap != auto { return gap }
  if key in from-mat { return from-mat.at(key) }
  if "gap" in from-mat { return from-mat.gap }
  if key == "row-gap" { math.mat.row-gap } else { math.mat.column-gap }
}

/// Scales a gap specification (single value or array).
#let _scale(spec, f) = if type(spec) == array { spec.map(x => x * f) } else { spec * f }

/// A matrix with the features of LaTeX's nicematrix.
///
/// Use it like `mat`: `$ nicemat(1, dots.c, 1; dots.v, dots.down, dots.v; 1, dots.c, 1) $`.
/// Dots symbols become dotted leaders that stretch between cells. See the
/// README for all options and markers.
#let nicemat(
  ..body,
  delim: auto,
  delim-fill: auto,
  align: auto,
  gap: auto,
  row-gap: auto,
  column-gap: auto,
  augment: none,
  hlines: none,
  vlines: none,
  hvlines: false,
  borders: auto,
  stroke: auto,
  fill: none,
  corners: none,
  first-row: false,
  last-row: false,
  first-col: false,
  last-col: false,
  map-cells: none,
  cell-space: 0pt,
  margin: auto,
  column-width: auto,
  baseline: horizon,
  small: auto,
  dots: (:),
  background: none,
  foreground: none,
  name: none,
  debug: false,
) = {
  if body.named().len() > 0 {
    panic("nicematrix: unknown argument(s) " + body.named().keys().map(k => "`" + k + "`").join(", "))
  }
  let pos = body.pos()
  // A `mat` element (from `show math.mat: nicemat`) provides the rows and
  // its own settings.
  let from-mat = (:)
  if pos.len() == 1 and type(pos.at(0)) == content and pos.at(0).func() == math.mat {
    let m = pos.at(0)
    pos = m.rows
    for k in ("delim", "align", "augment", "gap", "row-gap", "column-gap") {
      if m.has(k) { from-mat.insert(k, m.at(k)) }
    }
  }
  let first-row = to-bool(first-row, name: "first-row")
  let last-row = to-bool(last-row, name: "last-row")
  let first-col = to-bool(first-col, name: "first-col")
  let last-col = to-bool(last-col, name: "last-col")
  let small-opt = if small == auto { auto } else { to-bool(small, name: "small") }
  // `debug`: `true` (cells and rules), `"cells"`, `"rules"` or `false`.
  let debug = {
    let s = if type(debug) == bool { if debug { "all" } else { "none" } } else { plain-text(debug).trim() }
    if s == "true" { "all" } else if s == "false" { "none" } else if s in ("all", "none", "cells", "rules") { s } else {
      panic("nicematrix: `debug` must be `true`, `false`, `\"cells\"` or `\"rules\"`, got " + repr(debug))
    }
  }
  let name = if name == none { none } else if type(name) == str { name } else { plain-text(name).trim() }
  if to-bool(hvlines, name: "hvlines") {
    if hlines == none { hlines = true }
    if vlines == none { vlines = true }
  }
  let borders = if borders == auto { auto } else { to-bool(borders, name: "borders") }
  if type(dots) != dictionary { panic("nicematrix: `dots` must be a dictionary of options") }
  for k in dots.keys() {
    if k not in dots-defaults { panic("nicematrix: unknown `dots` option `" + k + "`") }
  }
  let user-dots = dots
  let augment = if augment == none { from-mat.at("augment", default: none) } else { augment }

  context {
    let delim = if delim != auto { delim } else { from-mat.at("delim", default: math.mat.delim) }
    let align = if align != auto { align } else { from-mat.at("align", default: math.mat.align) }
    let row-gap = _gap(row-gap, gap, from-mat, "row-gap")
    let column-gap = _gap(column-gap, gap, from-mat, "column-gap")
    // `small: auto`: script-size cells in inline equations (under
    // `nicemat-setup`), exactly like `mat` there; `small: true` is the
    // `small` of nicematrix, which also tightens the gaps.
    // The math style: that of the equation (level 0 in display equations,
    // 1 in inline ones under `nicemat-setup`, more when nested), or forced.
    let level = math-level()
    let (st, scale-gaps) = if small-opt == auto { (math-style(level), false) } else if small-opt {
      ((matrix: 1, cells: 2, flag: level >= 1), true)
    } else { (math-style(0), false) }
    let small = st.cells >= 2
    if scale-gaps and row-gap == math.mat.row-gap { row-gap = _scale(row-gap, 0.7) }
    if scale-gaps and column-gap == math.mat.column-gap { column-gap = _scale(column-gap, 0.7) }
    // Smaller dots in small cells, unless given.
    let dots = dots-defaults + user-dots
    if small {
      for k in ("radius", "spacing", "shorten") {
        if k not in user-dots { dots.insert(k, dots-defaults.at(k) * 0.7) }
      }
    }

    let mets = math-metrics(style: st)
    let default-stroke = merge-stroke((paint: text.fill, thickness: 0.05em.to-absolute(), cap: "square"), stroke)
    let grid = parse-body(rows-of(pos), auto-dots: to-bool(dots.symbols, name: "dots.symbols"))
    let (R, C) = (grid.nrows, grid.ncols)
    let r0 = if first-row { 1 } else { 0 }
    let r1 = if last-row { R - 1 } else { R }
    let c0 = if first-col { 1 } else { 0 }
    let c1 = if last-col { C - 1 } else { C }
    if r0 >= r1 or c0 >= c1 {
      panic("nicematrix: the exterior rows/columns leave no room for the matrix itself")
    }

    // Cells written on several lines with `\`.
    grid.cells = grid.cells.map(c => {
      let ls = if c.kind == "cell" { _split-lines(c.body) } else { none }
      if ls == none { c } else { c + (lines: ls) }
    })
    // Transform cell contents (code-for-first-row, RowStyle, …), line by line.
    if map-cells != none {
      grid.cells = grid.cells.map(c => {
        if c.kind != "cell" { c }
        else if "lines" in c { c + (lines: c.lines.map(l => map-cells(c.i, c.j, l))) }
        else { c + (body: map-cells(c.i, c.j, c.body)) }
      })
    }

    // --- Horizontal alignment of every cell.
    let align-at(i, j) = {
      if type(align) == function { h-align(align(i, j)) }
      else if first-col and j == 0 { right }
      else if last-col and j == C - 1 { left }
      else if type(align) == array { h-align(pick(align, j)) }
      else { h-align(align) }
    }
    let cell-align(c) = {
      let al = c.opts.at("align", default: auto)
      if al != auto { h-align(al) } else if c.colspan > 1 { center } else { align-at(c.i, c.j) }
    }
    let line-opts = (align: cell-align, gap: pick(row-gap, 0))
    grid.cells = grid.cells.map(c => _measure-record(c, st, dots, line-opts))

    let (lpair, rpair) = delim-pair(delim)
    let has-delim = lpair != none or rpair != none
    let cs = sides(cell-space)
    let cell-space = (top: abs-len(cs.top), bottom: abs-len(cs.bottom))
    let margin = if margin == auto {
      // Borders and fills need some room around the cells; so do the paths
      // and floods of pavemat, which always pads its grid.
      let pavemat-like = grid.decos.any(d => d.nicematrix in ("pave", "flood"))
      let pad = pavemat-like or (not has-delim and (fill != none or hlines == true or vlines == true))
      let (gx, gy) = (abs-len(pick(column-gap, 0)) / 2, abs-len(pick(row-gap, 0)) / 2)
      if pad { (left: gx, right: gx, top: gy, bottom: gy) } else { sides(0pt) }
    } else {
      let s = sides(margin)
      (left: abs-len(s.left), right: abs-len(s.right), top: abs-len(s.top), bottom: abs-len(s.bottom))
    }

    // --- Vertical layout, then the delimiters (their width depends only on
    // the height), then the horizontal layout.
    // Horizontal braces in rows: their height counts for the row (brace above
    // the matrix in the rows before the last exterior row, below in it).
    grid.cells = grid.cells.map(c => {
      if c.kind != "brace" or c.dir != "h" { return c }
      let over = c.i < r1
      let hb = hbrace-eq(2em.to-absolute(), c.label, over: over, fill: c.opts.at("fill", default: auto))
      c + (over: over, m: (w: 0pt, a: if over { hb.a } else { 0pt }, d: if over { 0pt } else { hb.d }, empty: false))
    })

    let ly = layout-rows(grid, mets, (row-gap: row-gap, cell-space: cell-space, margin: margin, r0: r0, r1: r1))
    let H = ly.main.bottom - ly.main.top
    let lglyph = if lpair != none { delim-glyph(lpair, H, side: left, fill: delim-fill, style: st) } else { none }
    let rglyph = if rpair != none { delim-glyph(rpair, H, side: right, fill: delim-fill, style: st) } else { none }
    let prep = prepare-submatrices(grid.decos, R, C, ly.rows, main: (r0, r1, c0, c1))
    // Vertical braces in columns: their width counts for the column.
    grid.cells = grid.cells.map(c => {
      if c.kind != "brace" or c.dir != "v" { return c }
      let right = c.j >= c0
      let h = ly.rows.at(c.i + c.rowspan - 1).bottom - ly.rows.at(c.i).top
      let vb = vbrace-eq(h, c.label, right: right, fill: c.opts.at("fill", default: auto))
      c + (right: right, m: (w: vb.w, a: 0pt, d: 0pt, empty: false))
    })
    let col-opts = (
      column-gap: column-gap,
      column-width: column-width,
      group: none,
      c0: c0,
      c1: c1,
      need-left: prep.need-left,
      need-right: prep.need-right,
      margin: margin,
      delim-w: (if lglyph != none { lglyph.w } else { 0pt }, if rglyph != none { rglyph.w } else { 0pt }),
    )
    let lx = layout-cols(grid, col-opts)
    // Inside a `nicemat-group`: publish the natural widths, use the maxima.
    let gid = group-state.get()
    let group-meta = none
    if gid != none {
      let natural = lx.cols.map(c => c.right - c.left)
      group-meta = metadata((group: gid, cols: natural, delims: col-opts.delim-w))
      let shared = group-widths(gid)
      if shared != none {
        col-opts.group = shared.cols
        col-opts.delim-w = (calc.max(col-opts.delim-w.at(0), shared.delims.at(0)), calc.max(col-opts.delim-w.at(1), shared.delims.at(1)))
        lx = layout-cols(grid, col-opts)
      }
    }
    let rows = ly.rows
    let cols = lx.cols
    let main = ly.main + lx.main

    // --- Position of every record: slot, content box and baseline.
    grid.cells = grid.cells.map(c => {
      let (i, j) = (c.i, c.j)
      let (i2, j2) = (i + c.rowspan - 1, j + c.colspan - 1)
      let slot = (x0: cols.at(j).left, x1: cols.at(j2).right, y0: rows.at(i).top, y1: rows.at(i2).bottom)
      let al = c.opts.at("align", default: auto)
      let ha = cell-align(c)
      let va = if al != auto { v-align(al, fallback: none) } else { none }
      let x = slot.x0 + align-offset(ha, slot.x1 - slot.x0, c.m.w)
      let base = if c.rowspan == 1 and va == none { rows.at(i).base } else {
        let va = if va == none { horizon } else { va }
        if va == top { slot.y0 + c.m.a }
        else if va == bottom { slot.y1 - c.m.d }
        else { (slot.y0 + slot.y1) / 2 + (c.m.a - c.m.d) / 2 }
      }
      c + (x: x, base: base, slot: slot, box: (x0: x, x1: x + c.m.w, y0: base - c.m.a, y1: base + c.m.d))
    })

    // --- Baseline of the whole matrix.
    let y-base = if baseline == horizon or baseline == auto {
      (main.top + main.bottom) / 2 + mets.axis
    } else if baseline == top {
      rows.at(r0).base
    } else if baseline == bottom {
      rows.at(r1 - 1).base
    } else if type(baseline) == dictionary and "line" in baseline {
      // Align a rule on the math axis (nicematrix's `baseline=line-i`); the
      // rule is counted within the main block, like `hlines`.
      let k = r0 + norm-index(to-int(baseline.line, name: "baseline"), r1 - r0)
      let y = if k <= r0 { main.top } else if k >= r1 { main.bottom } else {
        (rows.at(k - 1).bottom + rows.at(k).top) / 2
      }
      y + mets.axis
    } else {
      rows.at(norm-index(to-int(baseline, name: "baseline"), R)).base
    }

    // --- Items to place, by layer: (x, y, body) with (x, y) the top-left
    // corner of the placed content; and bounds rectangles for the box size.
    let layers = (under: (), rules: (), cells: (), over: ())
    let bounds = ((x0: 0pt, x1: lx.width, y0: calc.min(main.top, rows.at(0).top), y1: calc.max(main.bottom, rows.at(R - 1).bottom)),)
    let place-eq(e, x, base) = (x: x, y: base - BIG, body: placeable(e))

    // Delimiters of the main block.
    let dy = (main.top + main.bottom) / 2 + mets.axis
    if lglyph != none {
      let x = main.left - lglyph.w
      layers.over.push(place-eq(lglyph.body, x, dy))
      bounds.push((x0: x, x1: main.left, y0: dy - lglyph.a, y1: dy + lglyph.d))
    }
    if rglyph != none {
      layers.over.push(place-eq(rglyph.body, main.right, dy))
      bounds.push((x0: main.right, x1: main.right + rglyph.w, y0: dy - rglyph.a, y1: dy + rglyph.d))
    }

    // Cell contents.
    for c in grid.cells {
      if c.kind == "cell" {
        layers.cells.push(place-eq(c.eq, c.x, c.base))
        bounds.push(c.box)
      }
    }

    // Diagonal boxes: the diagonal of the tile and the two labels.
    for c in grid.cells.filter(c => c.kind == "diagbox") {
      let (j2, i2) = (c.j + c.colspan - 1, c.i + c.rowspan - 1)
      let t = (x0: lx.tiles.at(c.j).left, x1: lx.tiles.at(j2).right, y0: ly.tiles.at(c.i).top, y1: ly.tiles.at(i2).bottom)
      let st = merge-stroke(default-stroke, c.opts.at("stroke", default: auto))
      layers.rules.push((x: t.x0, y: t.y0, body: line(start: (0pt, 0pt), end: (t.x1 - t.x0, t.y1 - t.y0), stroke: st)))
      let pad = 0.1em.to-absolute()
      layers.cells.push(place-eq(c.lower-eq, t.x0 + pad, t.y1 - pad - c.ml.d))
      layers.cells.push(place-eq(c.upper-eq, t.x1 - pad - c.mu.w, t.y0 + pad + c.mu.a))
    }

    // --- Dotted leaders.
    let bound-subs = prep.subs.filter(s => s.bound)
    let bounds-of(i, j) = {
      let (rmin, rmax) = if i < r0 or i >= r1 { (i, i) } else { (r0, r1 - 1) }
      let (cmin, cmax) = if j < c0 or j >= c1 { (j, j) } else { (c0, c1 - 1) }
      for s in bound-subs {
        if s.i0 <= i and i <= s.i1 and s.j0 <= j and j <= s.j1 {
          (rmin, rmax) = (calc.max(rmin, s.i0), calc.min(rmax, s.i1))
          (cmin, cmax) = (calc.max(cmin, s.j0), calc.min(cmax, s.j1))
        }
      }
      (rmin, rmax, cmin, cmax)
    }
    let geo = (R: R, C: C, r0: r0, r1: r1, c0: c0, c1: c1, rows: rows, cols: cols)
    let lead = resolve-leaders(grid, geo, bounds-of, dots, mets)
    layers.over += lead.items
    bounds += lead.bounds

    // --- Empty corners, fills and block decorations.
    let cell-at(i, j) = grid.cells.at(grid.own.at(i).at(j))
    let corner = corner-cells(corners, R, C, r0, r1, c0, c1, (i, j) => {
      let c = cell-at(i, j)
      c.kind in ("cell", "pad") and c.m.empty and c.rowspan == 1 and c.colspan == 1
    })
    let ctiles = lx.tiles
    let rtiles = ly.tiles
    let tile(i0, j0, i1, j1) = (x0: ctiles.at(j0).left, x1: ctiles.at(j1).right, y0: rtiles.at(i0).top, y1: rtiles.at(i1).bottom)
    let rect-item(r, fill: none, stroke: none, radius: 0pt, outset: 0pt) = {
      let o = sides(outset)
      let (o-l, o-r, o-t, o-b) = (abs-len(o.left), abs-len(o.right), abs-len(o.top), abs-len(o.bottom))
      (x: r.x0 - o-l, y: r.y0 - o-t, body: rect(width: r.x1 - r.x0 + o-l + o-r, height: r.y1 - r.y0 + o-t + o-b,
        fill: fill, stroke: stroke, radius: radius, inset: 0pt))
    }

    // `fill`: a color, an array (cycled over the columns) or a function
    // `(i, j) => color`, for the cells of the main block outside the corners.
    let fill-at(i, j) = {
      if fill == none or corner.at(i).at(j) { none }
      else if type(fill) == function { fill(i, j) }
      else if type(fill) == array { fill.at(calc.rem(j - c0, fill.len())) }
      else { fill }
    }
    let block-fill(c) = c.opts.at("fill", default: none)
    if fill != none {
      // Runs of equal fills in each row, merged with identical runs below, to
      // avoid hairline seams between tiles.
      let runs = ()
      for i in range(r0, r1) {
        let j = c0
        while j < c1 {
          let c = cell-at(i, j)
          let f = if c.explicit and block-fill(c) != none { none } else { fill-at(i, j) }
          let j2 = j
          while j2 + 1 < c1 {
            let c2 = cell-at(i, j2 + 1)
            let f2 = if c2.explicit and block-fill(c2) != none { none } else { fill-at(i, j2 + 1) }
            if f2 == f { j2 += 1 } else { break }
          }
          if f != none { runs.push((i0: i, i1: i, j0: j, j1: j2, f: f)) }
          j = j2 + 1
        }
      }
      let merged = ()
      for r in runs {
        let k = merged.position(m => m.i1 == r.i0 - 1 and m.j0 == r.j0 and m.j1 == r.j1 and m.f == r.f)
        if k == none { merged.push(r) } else { merged.at(k).i1 = r.i1 }
      }
      for r in merged { layers.under.push(rect-item(tile(r.i0, r.j0, r.i1, r.j1), fill: r.f)) }
    }

    // Blocks: `cell(fill:, stroke:, radius:, outset:)`.
    for c in grid.cells {
      if not c.explicit { continue }
      let (f, st) = (block-fill(c), c.opts.at("stroke", default: none))
      if f == none and st == none { continue }
      let t = tile(c.i, c.j, c.i + c.rowspan - 1, c.j + c.colspan - 1)
      let radius = c.opts.at("radius", default: 0pt)
      let outset = c.opts.at("outset", default: 0pt)
      if f != none { layers.under.push(rect-item(t, fill: f, radius: radius, outset: outset)) }
      if st != none {
        layers.rules.push(rect-item(t, stroke: side-stroke(default-stroke, st), radius: radius, outset: outset))
      }
    }

    // --- Rules.
    let specs = ()
    // Rules only live in the main block, so their positions count within it,
    // exactly like the `augment` of `mat`: line 0 is the top (left) border
    // and negative numbers count from the end.
    let opt-lines(dir, spec, st) = {
      let (m0, m1) = if dir == "h" { (r0, r1) } else { (c0, c1) }
      let (t0, t1) = if dir == "h" { (c0, c1) } else { (r0, r1) }
      let outer = if borders == auto { not has-delim } else { borders }
      line-indices(spec, m1 - m0, 0, m1 - m0, outer).map(k => (dir: dir, k: m0 + k, start: t0, end: t1, stroke: st, marker: false))
    }
    specs += opt-lines("h", hlines, default-stroke)
    specs += opt-lines("v", vlines, default-stroke)
    if augment != none {
      let aug = if type(augment) == dictionary { augment } else { (vline: augment) }
      let ast = merge-stroke(default-stroke, aug.at("stroke", default: auto))
      for (key, dir) in (("hline", "h"), ("vline", "v")) {
        let v = aug.at(key, default: none)
        if v == none { continue }
        // Like `mat`, augmentation lines count within the main block.
        let (n, m0) = if dir == "h" { (r1 - r0, r0) } else { (c1 - c0, c0) }
        let (t0, t1) = if dir == "h" { (c0, c1) } else { (r0, r1) }
        for k in to-int-list(v, name: "augment") {
          specs.push((dir: dir, k: m0 + norm-index(k, n), start: t0, end: t1, stroke: ast, marker: false, augment: true))
        }
      }
    }
    // Markers: their position comes from where they are written, or from
    // `y` / `x`; `start` and `end` are columns (rows) of the main block.
    let main-index(v, m0, n, name) = m0 + norm-index(to-int(v, name: name), n)
    for m in grid.hlines {
      let k = if "y" in m { main-index(m.y, r0, r1 - r0, "y") } else { m.pos }
      let st = merge-stroke(default-stroke, m.at("stroke", default: auto))
      let start = if m.at("start", default: none) == none { c0 } else { main-index(m.start, c0, c1 - c0, "start") }
      let end = if m.at("end", default: none) == none { c1 } else { main-index(m.end, c0, c1 - c0, "end") }
      specs.push((dir: "h", k: k, start: start, end: end, stroke: st, marker: true))
    }
    for m in grid.vlines {
      let k = if "x" in m { main-index(m.x, c0, c1 - c0, "x") } else { m.pos }
      let st = merge-stroke(default-stroke, m.at("stroke", default: auto))
      let start = if m.at("start", default: none) == none { r0 } else { main-index(m.start, r0, r1 - r0, "start") }
      let end = if m.at("end", default: none) == none { r1 } else { main-index(m.end, r0, r1 - r0, "end") }
      specs.push((dir: "v", k: k, start: start, end: end, stroke: st, marker: true))
    }
    specs += submatrix-rules(prep.subs, default-stroke)
    let rule-ctx = (
      R: R, C: C, r0: r0, r1: r1, c0: c0, c1: c1, own: grid.own, cells: grid.cells,
      blocks: lead.blocks, corner: corner, rows: rows, cols: cols, rtiles: rtiles, ctiles: ctiles,
      main: main, sep: 0.18em.to-absolute(),
    )
    layers.rules += rule-items(specs, rule-ctx)

    // --- Decorations.
    let full(c) = c.kind == "brace" or (c.kind == "cell" and not c.m.empty)
    // Horizontal ink extent of column j (over the rows `rr` or all rows).
    let x-extent(j, rr) = {
      let ris = if rr == none { range(R) } else { range(rr.at(0), rr.at(1) + 1) }
      let cs = ris.map(i => cell-at(i, j)).filter(c => full(c) and c.colspan == 1 and c.kind == "cell")
      if cs.len() == 0 { (cols.at(j).left, cols.at(j).right) } else {
        (calc.min(..cs.map(c => c.box.x0)), calc.max(..cs.map(c => c.box.x1)))
      }
    }
    // Vertical ink extent of row i (over the columns `cc` or the main ones).
    let y-extent(i, cc) = {
      let js = if cc == none { range(c0, c1) } else { range(cc.at(0), cc.at(1) + 1) }
      let cs = js.map(j => cell-at(i, j)).filter(c => full(c) and c.rowspan == 1 and c.kind == "cell")
      if cs.len() == 0 { (rows.at(i).top, rows.at(i).bottom) } else {
        (calc.min(..cs.map(c => c.box.y0)), calc.max(..cs.map(c => c.box.y1)))
      }
    }

    let sm = submatrix-items(prep.subs, x-extent, mets.axis)
    layers.over += sm.items
    bounds += sm.bounds

    // Braces written in the rows and columns (`\Hbrace`, `\Vbrace`).
    for c in grid.cells.filter(c => c.kind == "brace") {
      let fill = c.opts.at("fill", default: auto)
      let shift = abs-len(c.opts.at("shift", default: 0pt))
      if c.dir == "h" {
        let main-rows = (r0, r1 - 1)
        let x0 = x-extent(c.j, main-rows).at(0)
        let x1 = x-extent(c.j + c.colspan - 1, main-rows).at(1)
        let y = if c.over { rows.at(c.i).bottom - shift } else { rows.at(c.i).top + shift }
        let r = hbrace-items(x0, x1, y, c.label, over: c.over, fill: fill)
        layers.over += r.items
        bounds += r.bounds
      } else {
        let main-cols = (c0, c1 - 1)
        let y0 = y-extent(c.i, main-cols).at(0)
        let y1 = y-extent(c.i + c.rowspan - 1, main-cols).at(1)
        let x = if c.right { cols.at(c.j).left + shift } else { cols.at(c.j).right - shift }
        let vb = vbrace-eq(y1 - y0, c.label, right: c.right, fill: fill)
        let r = vbrace-items(vb, x, y0, y1, right: c.right, axis: mets.axis)
        layers.over += r.items
        bounds += r.bounds
      }
    }

    // Paths along the grid lines (pavemat): all of them bound the floods.
    let (nR, nC) = (r1 - r0, c1 - c0)
    let paths = grid.decos.filter(d => d.nicematrix == "pave").map(d => pave-segments(d, nR, nC, default-stroke))
    let all-segs = paths.flatten()
    // Positions of the rules, counted within the main block.
    let rule-y(k) = if k <= 0 { main.top } else if k >= nR { main.bottom } else { rtiles.at(r0 + k).top }
    let rule-x(k) = if k <= 0 { main.left } else if k >= nC { main.right } else { ctiles.at(c0 + k).left }
    let path-index = 0

    for d in grid.decos {
      let kind = d.nicematrix
      if kind == "pave" {
        for s in merge-segments(paths.at(path-index)) {
          if s.hidden and debug == "none" { continue }
          let st = if s.hidden { (paint: gray, thickness: 0.5pt, dash: "dotted") } else { s.stroke }
          if s.dir == "h" {
            let (x0, x1, y) = (rule-x(s.t0), rule-x(s.t1 + 1), rule-y(s.k))
            layers.rules.push((x: x0, y: y, body: line(start: (0pt, 0pt), end: (x1 - x0, 0pt), stroke: st)))
          } else {
            let (y0, y1, x) = (rule-y(s.t0), rule-y(s.t1 + 1), rule-x(s.k))
            layers.rules.push((x: x, y: y0, body: line(start: (0pt, 0pt), end: (0pt, y1 - y0), stroke: st)))
          }
        }
        path-index += 1
      } else if kind == "flood" {
        let (i, j) = to-coord(d.from, name: "from")
        let (i, j) = (norm-index(i, R) - r0, norm-index(j, C) - c0)
        if i < 0 or j < 0 or i >= nR or j >= nC {
          panic("nicematrix: `flood` must start in a cell of the matrix itself (not an exterior row or column)")
        }
        let f = d.at("fill", default: none)
        // One rectangle per run of cells in a row, to avoid seams.
        let cells = flood-cells((i, j), nR, nC, all-segs)
        for r in range(nR) {
          let js = cells.filter(c => c.at(0) == r).map(c => c.at(1)).sorted()
          let k = 0
          while k < js.len() {
            let k2 = k
            while k2 + 1 < js.len() and js.at(k2 + 1) == js.at(k2) + 1 { k2 += 1 }
            layers.under.push(rect-item(tile(r0 + r, c0 + js.at(k), r0 + r, c0 + js.at(k2)), fill: f))
            k = k2 + 1
          }
        }
      } else if kind == "span-brace" {
        let r = deco-range(d, R, C, main: (r0, r1, c0, c1))
        let fill = d.at("fill", default: auto)
        let shift = abs-len(d.at("shift", default: 0pt))
        let shorten = to-bool(d.at("shorten", default: false), name: "shorten")
        if d.dir == "h" {
          let side = d.at("side", default: top)
          let (x0, x1) = if shorten {
            (x-extent(r.j0, (r.i0, r.i1)).at(0), x-extent(r.j1, (r.i0, r.i1)).at(1))
          } else { (ctiles.at(r.j0).left, ctiles.at(r.j1).right) }
          let over = side != bottom
          let y = if over { rtiles.at(r.i0).top - shift } else { rtiles.at(r.i1).bottom + shift }
          let r = hbrace-items(x0, x1, y, d.label, over: over, fill: fill)
          layers.over += r.items
          bounds += r.bounds
        } else {
          let side = d.at("side", default: right)
          let (y0, y1) = if shorten {
            (y-extent(r.i0, (r.j0, r.j1)).at(0), y-extent(r.i1, (r.j0, r.j1)).at(1))
          } else { (rtiles.at(r.i0).top, rtiles.at(r.i1).bottom) }
          let gapx = 0.15em.to-absolute()
          let is-right = side != left
          // Clear the delimiters of the matrix when the brace is at its edge.
          let x = if is-right {
            if r.j1 == c1 - 1 and rglyph != none { main.right + rglyph.w + gapx } else { ctiles.at(r.j1).right }
          } else {
            if r.j0 == c0 and lglyph != none { main.left - lglyph.w - gapx } else { ctiles.at(r.j0).left }
          }
          let x = if is-right { x + shift } else { x - shift }
          let vb = vbrace-eq(y1 - y0, d.label, right: is-right, fill: fill)
          let r = vbrace-items(vb, x, y0, y1, right: is-right, axis: mets.axis)
          layers.over += r.items
          bounds += r.bounds
        }
      } else if kind == "region" {
        let r = deco-range(d, R, C, main: (r0, r1, c0, c1))
        let fit = d.at("fit", default: "cells")
        let rect = tile(r.i0, r.j0, r.i1, r.j1)
        if fit == "content" {
          let boxes = ()
          for i in range(r.i0, r.i1 + 1) {
            for j in range(r.j0, r.j1 + 1) {
              let c = cell-at(i, j)
              if full(c) and c.kind == "cell" { boxes.push(c.box) }
            }
          }
          if boxes.len() > 0 {
            rect = (
              x0: calc.min(..boxes.map(b => b.x0)), x1: calc.max(..boxes.map(b => b.x1)),
              y0: calc.min(..boxes.map(b => b.y0)), y1: calc.max(..boxes.map(b => b.y1)),
            )
          }
        }
        let it = region-item(d, rect, default-stroke)
        if to-bool(d.at("above", default: false), name: "above") { layers.over.push(it) } else { layers.under.push(it) }
      } else if kind == "dotline" {
        let (a, b) = (to-coord(d.from, name: "from"), to-coord(d.to, name: "to"))
        let (ia, ja) = (norm-index(a.at(0), R), norm-index(a.at(1), C))
        let (ib, jb) = (norm-index(b.at(0), R), norm-index(b.at(1), C))
        for (i, j, which) in ((ia, ja, "from"), (ib, jb, "to")) {
          if i < 0 or j < 0 or i >= R or j >= C {
            panic("nicematrix: `" + which + "` " + repr((i, j)) + " is outside the " + str(R) + "×" + str(C) + " grid")
          }
        }
        let (ca, cb) = (cell-at(ia, ja), cell-at(ib, jb))
        let opts = d
        for k in ("nicematrix", "from", "to", "connect", "bend") { let _ = opts.remove(k, default: none) }
        if d.at("connect", default: false) { opts = connect-preset + opts }
        let bend = to-angle(d.at("bend", default: 0deg), name: "bend")
        let (p0, p1) = dotline-points(ca, cb, bend: bend)
        let st = leader-style(dots, opts, at: (ia, ja))
        let s0 = if st.shorten-start == auto { st.shorten } else { st.shorten-start }
        let s1 = if st.shorten-end == auto { st.shorten } else { st.shorten-end }
        let r = leader-items(p0, p1, st + (shorten-start: s0, shorten-end: s1, bend: bend))
        layers.over += r.items
        bounds += r.bounds
      }
    }

    // --- Final box.
    let X0 = calc.min(..bounds.map(b => b.x0))
    let X1 = calc.max(..bounds.map(b => b.x1))
    let Y0 = calc.min(..bounds.map(b => b.y0))
    let Y1 = calc.max(..bounds.map(b => b.y1))

    // Geometry handed to `background` / `foreground` (and used by `debug`),
    // in the coordinates of the final box.
    let rect-of(r) = (x: r.x0 - X0, y: r.y0 - Y0, width: r.x1 - r.x0, height: r.y1 - r.y0)
    let geometry = (
      width: X1 - X0,
      height: Y1 - Y0,
      baseline: y-base - Y0,
      axis: y-base - Y0 - mets.axis,
      main: rect-of((x0: main.left, x1: main.right, y0: main.top, y1: main.bottom)),
      rows: rows.enumerate().map(((i, r)) => (
        top: r.top - Y0, baseline: r.base - Y0, bottom: r.bottom - Y0,
        tile-top: rtiles.at(i).top - Y0, tile-bottom: rtiles.at(i).bottom - Y0,
      )),
      cols: cols.enumerate().map(((j, c)) => (
        left: c.left - X0, right: c.right - X0,
        tile-left: ctiles.at(j).left - X0, tile-right: ctiles.at(j).right - X0,
      )),
      leaders: lead.lines.map(l => (
        dir: l.dir, from: l.from, to: l.to, open: l.open,
        start: (l.p0.at(0) - X0, l.p0.at(1) - Y0), end: (l.p1.at(0) - X0, l.p1.at(1) - Y0),
      )),
      cells: range(R).map(i => range(C).map(j => {
        let c = cell-at(i, j)
        rect-of(tile(i, j, i, j)) + (
          ink: rect-of(c.box),
          baseline: c.base - Y0,
          empty: c.m.empty,
          kind: c.kind,
          origin: (c.i, c.j),
        )
      })),
    )
    let hook(h) = if h == none { () } else {
      let body = if type(h) == function { h(geometry) } else { h }
      ((x: X0, y: Y0, body: body),)
    }

    let debug-items = ()
    let tiny(body, size: 3.5pt, fill: blue.darken(20%)) = box(fill: white.transparentize(20%), inset: 0.3pt,
      text(size: size, fill: fill, font: "DejaVu Sans Mono", top-edge: "bounds", bottom-edge: "bounds", body))
    if debug in ("all", "cells") {
      // Tiles, ink boxes and the coordinates of every cell.
      for i in range(R) {
        for j in range(C) {
          let c = cell-at(i, j)
          if c.i != i or c.j != j { continue }
          let t = tile(i, j, i + c.rowspan - 1, j + c.colspan - 1)
          debug-items.push((x: t.x0, y: t.y0, body: rect(width: t.x1 - t.x0, height: t.y1 - t.y0,
            stroke: (paint: gray, thickness: 0.3pt, dash: "dotted"))))
          if c.kind == "cell" and not c.m.empty {
            debug-items.push((x: c.box.x0, y: c.box.y0, body: rect(width: c.box.x1 - c.box.x0,
              height: c.box.y1 - c.box.y0, stroke: (paint: red.transparentize(50%), thickness: 0.2pt))))
          }
          debug-items.push((x: t.x0, y: t.y0, body: tiny(size: 3pt, fill: gray.darken(30%))[#i,#j]))
        }
      }
    }
    if debug in ("all", "rules") {
      // The numbers of the rules, as `hlines`, `vlines`, `augment` and
      // `pave` count them (within the main block): horizontal ones on the
      // left of the matrix, vertical ones above it.
      let line-st = (paint: blue.transparentize(55%), thickness: 0.3pt, dash: "densely-dotted")
      for k in range(nR + 1) {
        let y = rule-y(k)
        debug-items.push((x: main.left, y: y, body: line(length: main.right - main.left, stroke: line-st)))
        let b = tiny[#k]
        let m = measure(b)
        debug-items.push((x: X0 - m.width - 1pt, y: y - m.height / 2, body: b))
      }
      for k in range(nC + 1) {
        let x = rule-x(k)
        debug-items.push((x: x, y: main.top, body: line(angle: 90deg, length: main.bottom - main.top, stroke: line-st)))
        let b = tiny[#k]
        let m = measure(b)
        debug-items.push((x: x - m.width / 2, y: Y0 - m.height - 1pt, body: b))
      }
    }

    let order = (layers.under, hook(background), layers.rules, layers.cells, layers.over, hook(foreground), debug-items)
    box(width: X1 - X0, height: Y1 - Y0, baseline: Y1 - y-base, {
      for layer in order {
        for it in layer { place(top + left, dx: it.x - X0, dy: it.y - Y0, it.body) }
      }
      if group-meta != none [#group-meta <nicematrix-group>]
      // Named matrices publish their geometry at their top-left corner, for
      // `nicemat-cell` and `nicemat-connect`.
      if name != none { place(top + left, [#metadata((nicematrix-anchor: name, geometry: geometry)) <nicematrix-anchor>]) }
    })
  }
}

/// `nicemat` without delimiters, like nicematrix's `{NiceArray}`.
#let nicearray = nicemat.with(delim: none)
