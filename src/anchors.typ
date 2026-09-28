/// Named matrices: `nicemat(name: "A", ..)` publishes its geometry, so that
/// cells of different matrices can be located and connected (the analogue of
/// TikZ's `remember picture` with the nodes of nicematrix).

#import "util.typ": plain-text, to-coord, norm-index, to-angle
#import "leaders.typ": leader-style, dotline-points, connect-preset
#import "draw.typ": leader-items
#import "nicemat.typ": dots-defaults

#let _name(v) = if type(v) == str { v } else { plain-text(v).trim() }

/// Where the cell `coord` of the matrix named `name` is on the page, or
/// `none` while the matrix has not been laid out yet (Typst lays the
/// document out again once it is known). Must be called in a context.
///
/// Returns a dictionary with `page`, the tile of the cell (`x`, `y`,
/// `width`, `height`, in absolute page coordinates), `ink` (the rectangle of
/// its content, same keys) and `baseline`.
#let nicemat-cell(name, coord) = {
  let name = _name(name)
  let found = query(<nicematrix-anchor>).filter(m => m.value.nicematrix-anchor == name)
  if found.len() == 0 { return none }
  if found.len() > 1 {
    panic("nicematrix: " + str(found.len()) + " matrices are named `" + name + "`; names must be unique")
  }
  let m = found.first()
  let p = m.location().position()
  let cells = m.value.geometry.cells
  let (R, C) = (cells.len(), cells.first().len())
  let (i, j) = to-coord(coord, name: "cell")
  let (i, j) = (norm-index(i, R), norm-index(j, C))
  if i < 0 or j < 0 or i >= R or j >= C {
    panic("nicematrix: cell " + repr(coord) + " is outside the " + str(R) + "×" + str(C) + " matrix `" + name + "`")
  }
  let c = cells.at(i).at(j)
  let shift(r) = (x: p.x + r.x, y: p.y + r.y, width: r.width, height: r.height)
  shift(c) + (page: p.page, ink: shift(c.ink), baseline: p.y + c.baseline)
}

/// Draws a line between cells of named matrices, on the same page:
/// `nicemat-connect(("A", (0, 2)), ("B", (1, 0)))`.
///
/// By default an arrow, like `connect`; it takes the same options as
/// `dotline` (`bend`, `stroke` (`auto` for dots), `marks`, `shorten`,
/// `above`, `below`, …). Put it anywhere on the page of the matrices, for
/// instance just after them; it takes no room.
#let nicemat-connect(from, to, ..args) = {
  if args.pos().len() > 0 {
    panic("nicematrix: `nicemat-connect` takes two cells `(name, (row, col))` and named options")
  }
  for (v, which) in ((from, "from"), (to, "to")) {
    if type(v) != array or v.len() != 2 {
      panic("nicematrix: `" + which + "` of `nicemat-connect` must be `(name, (row, col))`, got " + repr(v))
    }
  }
  let opts = args.named()
  let bend = to-angle(opts.remove("bend", default: 0deg), name: "bend")
  for k in opts.keys() {
    if k not in dots-defaults and k not in ("above", "below", "middle") {
      panic("nicematrix: unknown option `" + k + "` for `nicemat-connect`")
    }
  }
  context {
    let a = nicemat-cell(..from)
    let b = nicemat-cell(..to)
    if a != none and b != none {
      let here = here().position()
      if a.page != b.page {
        panic("nicematrix: `nicemat-connect` needs both matrices on the same page (`" + _name(from.at(0))
          + "` is on page " + str(a.page) + ", `" + _name(to.at(0)) + "` on page " + str(b.page) + ")")
      }
      if here.page != a.page {
        panic("nicematrix: put `nicemat-connect` on the page of the matrices it connects (page " + str(a.page) + ")")
      }
      let as-box(r) = (box: (x0: r.ink.x, x1: r.ink.x + r.ink.width, y0: r.ink.y, y1: r.ink.y + r.ink.height))
      let (p0, p1) = dotline-points(as-box(a), as-box(b), bend: bend)
      let st = leader-style(dots-defaults + connect-preset, opts)
      let s0 = if st.shorten-start == auto { st.shorten } else { st.shorten-start }
      let s1 = if st.shorten-end == auto { st.shorten } else { st.shorten-end }
      let r = leader-items(p0, p1, st + (shorten-start: s0, shorten-end: s1, bend: bend))
      box(width: 0pt, height: 0pt, {
        for it in r.items { place(top + left, dx: it.x - here.x, dy: it.y - here.y, it.body) }
      })
    }
  }
}
