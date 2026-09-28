/// Turns the arguments of `nicemat` into a grid of cell records.
///
/// A record is a dictionary:
/// - `i`, `j`: row and column of the top-left position (0-based, as written),
/// - `rowspan`, `colspan`,
/// - `kind`: `"cell"`, `"leader"`, `"brace"`, `"diagbox"` or `"pad"` (a
///   missing cell),
/// - `body`: the content (cells), `label` (braces),
/// - `dir`: `"l" | "c" | "v" | "d" | "i"` (leaders), `"h" | "v"` (braces),
/// - `opts`: the remaining named options of the marker,
/// - `explicit`: whether it came from `cell(..)`.

#import "util.typ": to-int, to-bool
#import "markers.typ": marker-of, auto-leader

#let _line-kinds = ("hline", "vline")
#let _deco-kinds = ("submatrix", "region", "dotline", "span-brace", "pave", "flood")

#let _without(d, ..keys) = {
  let d = d
  for k in keys.pos() { if k in d { let _ = d.remove(k) } }
  d
}

/// Splits positional arguments into rows. Math calls with `;` give arrays;
/// a flat list is a single row, like `mat`.
#let rows-of(pos) = {
  if pos.len() == 0 { return () }
  if not pos.any(p => type(p) == array) { return (pos,) }
  let rows = ()
  for p in pos {
    if type(p) == array { rows.push(p) }
    else if marker-of(p) != none { rows.push((p,)) }
    else {
      panic("nicematrix: cannot mix rows (arrays) and single cells in the arguments; got " + repr(p))
    }
  }
  rows
}

#let _as-content(v) = {
  if v == none { [] }
  else if type(v) == content { v }
  else if type(v) in (str, symbol, int, float) { [#v] }
  else if type(v) == function { panic("nicematrix: unexpected function in a cell (did you mean to call it?)") }
  else { [#repr(v)] }
}

#let _record(it, m, i, j, auto-dots) = {
  let base = (i: i, j: j, rowspan: 1, colspan: 1, kind: "cell", body: none, dir: none,
              label: none, opts: (:), explicit: false)
  if m == none {
    let d = if auto-dots { auto-leader(it) } else { none }
    if d != none { return base + (kind: "leader", dir: d, body: _as-content(it)) }
    return base + (body: _as-content(it))
  }
  let kind = m.nicematrix
  if kind == "leader" {
    let span = to-int(m.at("span", default: 1), name: "span")
    let dir = m.dir
    let rec = base + (kind: "leader", dir: dir, opts: _without(m, "nicematrix", "dir", "span"), span: span,
                      // An explicit `span` (even 1) gives the semantics of `\Hdotsfor`.
                      dotsfor: "span" in m)
    if span > 1 {
      if dir in ("l", "c") { rec.colspan = span }
      else if dir == "v" { rec.rowspan = span }
      else { panic("nicematrix: `span` is not available for diagonal leaders") }
    }
    rec.body = if dir == "l" { $dots.h$ } else if dir == "c" { $dots.c$ } else if dir == "v" { $dots.v$ } else if dir == "d" { $dots.down$ } else { $dots.up$ }
    return rec
  }
  if kind == "diagbox" {
    return base + (kind: "diagbox", body: [], lower: m.lower, upper: m.upper, opts: _without(m, "nicematrix", "lower", "upper"))
  }
  if kind == "cell" {
    let inner = marker-of(m.body)
    if inner != none and inner.nicematrix == "diagbox" {
      // `cell(diagbox(x, y), rowspan: ..)`: a diagonal box over a block.
      return base + (
        kind: "diagbox", body: [], lower: inner.lower, upper: inner.upper,
        rowspan: to-int(m.at("rowspan", default: 1), name: "rowspan"),
        colspan: to-int(m.at("colspan", default: 1), name: "colspan"),
        opts: _without(m, "nicematrix", "body", "rowspan", "colspan") + _without(inner, "nicematrix", "lower", "upper"),
        explicit: true,
      )
    }
    return base + (
      kind: "cell",
      body: _as-content(m.body),
      rowspan: to-int(m.at("rowspan", default: 1), name: "rowspan"),
      colspan: to-int(m.at("colspan", default: 1), name: "colspan"),
      opts: _without(m, "nicematrix", "body", "rowspan", "colspan"),
      explicit: true,
    )
  }
  if kind == "brace" {
    let span = to-int(m.at("span", default: 1), name: "span")
    let rec = base + (kind: "brace", dir: m.dir, label: m.label, opts: _without(m, "nicematrix", "dir", "label", "span"))
    if m.dir == "h" { rec.colspan = span } else { rec.rowspan = span }
    return rec
  }
  // Any other marker used as a cell: treat as normal content.
  base + (body: _as-content(it))
}

/// Parses rows into a grid.
///
/// Returns `(nrows, ncols, cells, own, hlines, vlines, decos)` where `own`
/// is a 2D array giving, for every position, the index of the record that
/// covers it.
#let parse-body(rows, auto-dots: true) = {
  let cells = ()
  let owner = (:)
  let hlines = ()
  let vlines = ()
  let decos = ()
  let key(i, j) = str(i) + "," + str(j)

  let i = 0
  for row in rows {
    let items = row.map(it => (it, marker-of(it)))
    let marker-row = row.len() > 0 and items.all(p => (
      p.at(1) != none and p.at(1).nicematrix in _line-kinds + _deco-kinds
    ))
    if marker-row {
      for (it, m) in items {
        if m.nicematrix == "hline" { hlines.push(m + (pos: i)) }
        else if m.nicematrix == "vline" { vlines.push(m + (pos: 0)) }
        else { decos.push(m) }
      }
      continue
    }
    let j = 0
    for (it, m) in items {
      if m != none {
        if m.nicematrix == "hline" { hlines.push(m + (pos: i + 1)); continue }
        if m.nicematrix == "vline" { vlines.push(m + (pos: j)); continue }
        if m.nicematrix in _deco-kinds { decos.push(m); continue }
      }
      while key(i, j) in owner { j += 1 }
      let rec = _record(it, m, i, j, auto-dots)
      if rec.rowspan < 1 or rec.colspan < 1 {
        panic("nicematrix: spans must be at least 1 (cell at " + key(i, j) + ")")
      }
      for di in range(rec.rowspan) {
        for dj in range(rec.colspan) { owner.insert(key(i + di, j + dj), cells.len()) }
      }
      cells.push(rec)
      j += rec.colspan
    }
    i += 1
  }

  let nrows = i
  let ncols = 0
  for c in cells {
    nrows = calc.max(nrows, c.i + c.rowspan)
    ncols = calc.max(ncols, c.j + c.colspan)
  }
  ncols = calc.max(ncols, 1)
  nrows = calc.max(nrows, 1)

  // Pad missing positions with empty cells, like `mat` does for short rows.
  let own = ()
  for i in range(nrows) {
    let r = ()
    for j in range(ncols) {
      let k = key(i, j)
      if k not in owner {
        owner.insert(k, cells.len())
        cells.push((i: i, j: j, rowspan: 1, colspan: 1, kind: "pad", body: [], dir: none,
                    label: none, opts: (:), explicit: false))
      }
      r.push(owner.at(k))
    }
    own.push(r)
  }

  (nrows: nrows, ncols: ncols, cells: cells, own: own, hlines: hlines, vlines: vlines, decos: decos)
}
