/// Markers are the small "commands" users put among the cells of a
/// `nicemat`: leaders, spanning cells, rules, braces and decorations.
///
/// Each marker is a `metadata` element carrying a dictionary with a
/// `nicematrix` key naming its kind, followed by a fallback: what the marker
/// shows outside a `nicemat` (the dots of a leader, the body of a cell, …).
/// Being content, a marker survives inside the cells of a regular `mat` (so
/// `show math.mat: nicemat` sees it).

#import "util.typ": plain-text

#let _marker(kind, fallback: none, ..fields) = {
  if fields.pos().len() > 0 {
    panic("nicematrix: `" + kind + "` takes named arguments only, got " + repr(fields.pos()))
  }
  let m = metadata((nicematrix: kind, ..fields.named()))
  if fallback == none { m } else { [#m#fallback] }
}

/// Markers covering a rectangle of cells: two corners `from, to`, or whole
/// rows and columns with `row:` / `rows: (first, last)` / `col:` /
/// `cols: (first, last)` (the other direction defaults to the main block).
#let _ranged(kind, args) = {
  let pos = args.pos()
  if pos.len() == 2 { return _marker(kind, from: pos.at(0), to: pos.at(1), ..args.named()) }
  if pos.len() == 0 { return _marker(kind, ..args.named()) }
  panic("nicematrix: `" + kind + "` takes two corners `from, to`, or `row:`, `rows:`, `col:`, `cols:`; got "
    + str(pos.len()) + " positional arguments")
}

// --- Dotted leaders ---------------------------------------------------------

/// Horizontal leader on the baseline (like `\Ldots`, `\Hdotsfor`).
///
/// Named options: `span` (cover several columns, like `\Hdotsfor`),
/// `above`, `below`, `middle` (labels), `fill`, `stroke`, `radius`,
/// `spacing`, `shorten`, `shorten-start`, `shorten-end`, `nullify`,
/// `horizontal-labels`, `marks`.
#let ldots(..args) = _marker("leader", dir: "l", fallback: sym.dots.h, ..args)

/// Horizontal leader on the math axis (like `\Cdots`).
#let cdots(..args) = _marker("leader", dir: "c", fallback: sym.dots.c, ..args)

/// Vertical leader (like `\Vdots`; with `span`, like `\Vdotsfor`).
#let vdots(..args) = _marker("leader", dir: "v", fallback: sym.dots.v, ..args)

/// Diagonal leader going down to the right (like `\Ddots`).
/// `first: #true` makes this the reference for the parallel diagonals.
#let ddots(..args) = _marker("leader", dir: "d", fallback: sym.dots.down, ..args)

/// Diagonal leader going up to the right (like `\Iddots`).
#let iddots(..args) = _marker("leader", dir: "i", fallback: sym.dots.up, ..args)

// --- Cells and rules -------------------------------------------------------

/// A cell with options, possibly spanning several rows and columns (like
/// `\Block`). Covered positions are skipped automatically, as with
/// `table.cell`.
///
/// Options: `rowspan`, `colspan`, `fill`, `stroke`, `radius`, `outset`,
/// `align`, `transparent` (let rules cross the block), `empty` (force the
/// cell to count as empty or not, like `\NotEmpty`).
#let cell(body, ..args) = _marker("cell", fallback: body, body: body, ..args)

/// A horizontal rule. On its own row (`1, 2; hline(); 3, 4`) it separates the
/// neighbouring rows; inside a row it is drawn below that row.
/// Options: `start`, `end` (columns), `stroke`, `y` (explicit position).
#let hline(..args) = _marker("hline", ..args)

/// A vertical rule, drawn after the cell it follows (`1, vline(), 2`).
/// Options: `start`, `end` (rows), `stroke`, `x` (explicit position).
#let vline(..args) = _marker("vline", ..args)

/// A cell slashed diagonally, with `lower` in the bottom-left corner and
/// `upper` in the top-right one (like `\diagbox`). It can also be the body of
/// a spanning `cell`. Option: `stroke`.
#let diagbox(lower, upper, ..args) = _marker("diagbox", fallback: [#lower/#upper], lower: lower, upper: upper, ..args)

// --- Braces ----------------------------------------------------------------

#let _brace(kind, args) = {
  let pos = args.pos()
  let named = args.named()
  let ranged = ("row", "rows", "col", "cols").any(k => k in named)
  if ranged and pos.len() <= 1 {
    _marker("span-brace", dir: kind, label: pos.at(0, default: none), ..named)
  } else if pos.len() == 1 {
    _marker("brace", fallback: pos.at(0), dir: kind, label: pos.at(0), ..named)
  } else if pos.len() == 3 {
    _marker("span-brace", dir: kind, from: pos.at(0), to: pos.at(1), label: pos.at(2), ..named)
  } else if pos.len() == 0 {
    _marker("brace", dir: kind, label: none, ..named)
  } else {
    panic("nicematrix: `" + kind + "brace` takes a label (inside a row), `from, to, label`, or a label with `rows:` / `cols:`")
  }
}

/// A horizontal brace.
///
/// - `hbrace(label, span: n)` inside the first or last (exterior) row spans
///   `n` columns (like `\Hbrace`).
/// - `hbrace(from, to, label, side: top)` anywhere draws a brace above (or
///   below with `side: bottom`) the cells from `from` to `to` (like
///   `\OverBrace` / `\UnderBrace`).
/// - `hbrace(label, cols: (first, last))` (or `col:`, `rows:`, `row:`) does
///   the same for whole columns of the main block.
///
/// Options: `fill`, `shorten`, `shift`.
#let hbrace(..args) = _brace("h", args)

/// A vertical brace; see `hbrace`. The coordinate form takes
/// `side: right` (default) or `side: left`.
#let vbrace(..args) = _brace("v", args)

// --- Decorations -----------------------------------------------------------

/// Delimiters around a part of the matrix (like `\SubMatrix`).
///
/// Options: `delim` (default `"("`), `sup`, `sub`, `hlines`, `vlines`,
/// `stroke`, `slim`, `xshift`, `left-xshift`, `right-xshift`,
/// `extra-height`, `fill`, `reserve` (make room for the delimiters,
/// default true), `bound` (stop leaders at the sub-matrix, default true).
///
/// The rectangle is `from, to`, or whole rows and columns: `row: 1`,
/// `rows: (0, 2)`, `col: 3`, `cols: (1, 2)`.
#let submatrix(..args) = _ranged("submatrix", args)

/// A background shape over a rectangle of cells (like `\rectanglecolor`, or
/// the TikZ "highlight" recipe of nicematrix).
/// Options: `fill`, `stroke`, `radius`, `outset`, `fit` (`"cells"` or
/// `"content"`), `above` (draw over the cells instead of below).
/// The rectangle is `from, to`, or whole rows and columns as for `submatrix`.
#let region(..args) = _ranged("region", args)

/// A leader between two arbitrary cells (like `\line` in `\CodeAfter`).
/// Takes the same options as the leaders, and `bend` (an angle, or a number
/// of degrees): the line leaves and reaches the cells turned by that angle,
/// like TikZ's `bend left` (negative values bend to the right).
#let dotline(from, to, ..args) = _marker("dotline", from: from, to: to, ..args)

/// An arrow between two cells: a `dotline` drawn as a solid line with an
/// arrow head (`marks: "->"`). All options of `dotline` apply; `stroke: auto`
/// gives dots again.
#let connect(from, to, ..args) = _marker("dotline", from: from, to: to, connect: true, ..args)

/// A path along the grid lines (as in pavemat): a string of directions `W`
/// (up), `A` (left), `S` (down), `D` (right); lower-case letters move without
/// drawing; `(key: value, …)` changes the stroke of what follows, up to `]`.
/// Options: `from` (a grid point `(i, j)` counted within the matrix like the
/// rules, or a corner `top + left`, …), `stroke`, `chars` (other letters, e.g.
/// `(up: "U", down: "D", left: "L", right: "R")`).
#let pave(path, ..args) = _marker("pave", path: path, ..args)

/// Fills the cells connected to `from` without crossing a `pave` path (drawn
/// or hidden), like the fills of pavemat. Option: `fill`.
#let flood(from, ..args) = _marker("flood", from: from, ..args)

// --- Detection -------------------------------------------------------------

#let _is-space(c) = type(c) == content and (c.func() == [ ].func() or c == [])

/// The marker dictionary carried by `v`, or `none`.
#let marker-of(v) = {
  if type(v) == dictionary and "nicematrix" in v { return v }
  if type(v) != content { return none }
  if v.func() == metadata {
    let val = v.value
    if type(val) == dictionary and "nicematrix" in val { return val }
    return none
  }
  if v.has("children") {
    let ch = v.children
    // A marker with its fallback: `[#metadata(..)#fallback]`.
    if ch.len() == 2 and type(ch.at(0)) == content and ch.at(0).func() == metadata {
      let m = marker-of(ch.at(0))
      if m != none { return m }
    }
    let rest = ch.filter(c => not _is-space(c))
    if rest.len() == 1 { return marker-of(rest.first()) }
  }
  none
}

#let _dot-chars = ("…": "l", "⋯": "c", "⋮": "v", "⋱": "d", "⋰": "i")
#let _leader-fns = ((ldots, "l"), (cdots, "c"), (vdots, "v"), (ddots, "d"), (iddots, "i"))

/// If `v` is a plain dots symbol (`dots.c`, `...`, `dots.v`, …) or a bare
/// leader function (`cdots` without parentheses), returns the leader
/// direction; otherwise `none`.
#let auto-leader(v) = {
  if type(v) == function {
    for (f, d) in _leader-fns { if v == f { return d } }
    return none
  }
  if type(v) not in (symbol, str, content) { return none }
  let s = plain-text(v).trim()
  _dot-chars.at(s, default: none)
}
