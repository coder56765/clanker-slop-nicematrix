/// Drawing primitives. They return "items": dictionaries `(x, y, body)`
/// where `(x, y)` is where the top-left corner of `body` is placed, together
/// with bounds rectangles `(x0, y0, x1, y1)` for the final box size.

#import "metrics.typ": cell-eq, ink

#let _len(dx, dy) = calc.sqrt(calc.pow(dx / 1pt, 2) + calc.pow(dy / 1pt, 2)) * 1pt

/// A label set in script style, as a box of exactly its ink size.
#let label-box(body, fill: none, inset: 0pt) = {
  let e = cell-eq(body, small: true)
  let m = ink(e)
  let b = box(text(top-edge: "bounds", bottom-edge: "bounds", e))
  if fill != none { b = box(fill: fill, inset: inset, b) }
  (body: b, w: m.w + 2 * inset, h: m.a + m.d + 2 * inset)
}

/// Arrow head polygon with its tip at `(x, y)` pointing along `(ux, uy)`.
#let _arrow(x, y, ux, uy, size, paint) = {
  let (len, half) = (size, size * 0.45)
  let bx = x - ux * len
  let by = y - uy * len
  let pts = ((x, y), (bx + uy * half, by - ux * half), (bx - uy * half, by + ux * half))
  let x0 = calc.min(..pts.map(p => p.at(0)))
  let y0 = calc.min(..pts.map(p => p.at(1)))
  let x1 = calc.max(..pts.map(p => p.at(0)))
  let y1 = calc.max(..pts.map(p => p.at(1)))
  (
    item: (x: x0, y: y0, body: polygon(fill: paint, stroke: none, ..pts.map(p => (p.at(0) - x0, p.at(1) - y0)))),
    bound: (x0: x0, y0: y0, x1: x1, y1: y1),
  )
}

/// Draws a leader from `p0` to `p1`.
///
/// `s` is a dictionary with `fill`, `stroke` (`auto` for round dots), `radius`,
/// `spacing`, `shorten-start`, `shorten-end`, `marks`, `above`, `below`,
/// `middle`, `horizontal-labels`, `label-fill`; lengths already absolute.
/// Returns `(items, bounds)`.
#let leader-items(p0, p1, s) = {
  let items = ()
  let bounds = ()
  let (x0, y0) = p0
  let (x1, y1) = p1
  let (dx, dy) = (x1 - x0, y1 - y0)
  let l = _len(dx, dy)
  if l < 1pt or l > 500cm { return (items: (), bounds: ()) }
  let (ux, uy) = (dx / l, dy / l)
  let (s0, s1) = (s.shorten-start, s.shorten-end)
  let r = s.radius

  if s.stroke == auto {
    // Round dots, spaced evenly and centred on the line (nicematrix's
    // "standard" style).
    let n = calc.floor((l - s0 - s1) / s.spacing)
    if n >= 0 {
      let off = (l - s.spacing * n + s0 - s1) / 2
      for k in range(n + 1) {
        let t = off + s.spacing * k
        let (cx, cy) = (x0 + ux * t, y0 + uy * t)
        items.push((x: cx - r, y: cy - r, body: circle(radius: r, fill: s.fill, stroke: none)))
        bounds.push((x0: cx - r, y0: cy - r, x1: cx + r, y1: cy + r))
      }
    }
  } else {
    let (ax, ay) = (x0 + ux * s0, y0 + uy * s0)
    let (bx, by) = (x1 - ux * s1, y1 - uy * s1)
    let st = s.stroke
    items.push((x: ax, y: ay, body: line(start: (0pt, 0pt), end: (bx - ax, by - ay), stroke: st)))
    bounds.push((x0: calc.min(ax, bx), y0: calc.min(ay, by), x1: calc.max(ax, bx), y1: calc.max(ay, by)))
  }

  // Arrow tips.
  if s.marks != none {
    let m = s.marks
    let size = s.at("mark-size", default: 4pt)
    let paint = s.fill
    if m in ("->", "<->") {
      let a = _arrow(x1 - ux * s1, y1 - uy * s1, ux, uy, size, paint)
      items.push(a.item); bounds.push(a.bound)
    }
    if m in ("<-", "<->") {
      let a = _arrow(x0 + ux * s0, y0 + uy * s0, -ux, -uy, size, paint)
      items.push(a.item); bounds.push(a.bound)
    }
  }

  // Labels: `above`, `below` and `middle` (nicematrix's `^`, `_` and `:`).
  let (mx, my) = ((x0 + x1) / 2, (y0 + y1) / 2)
  let angle = calc.atan2(dx / 1pt, dy / 1pt)
  // Keep the text upright.
  if angle > 90deg + 0.1deg or angle < -90deg + 0.1deg { angle += 180deg }
  let (nx, ny) = (uy, -ux)
  if ny > 0 or (ny == 0 and nx < 0) { (nx, ny) = (-nx, -ny) }
  let sep = 0.3em.to-absolute() + r
  for (key, side) in (("above", 1), ("below", -1), ("middle", 0)) {
    let lbl = s.at(key, default: none)
    if lbl == none { continue }
    let lb = if side == 0 {
      label-box(lbl, fill: s.label-fill, inset: 0.17em.to-absolute())
    } else {
      label-box(lbl)
    }
    let (w, h) = (lb.w, lb.h)
    let dist = if side == 0 { 0pt } else if s.horizontal-labels {
      calc.abs(nx) * w / 2 + calc.abs(ny) * h / 2 + sep
    } else { h / 2 + sep }
    let (cx, cy) = (mx + nx * dist * side, my + ny * dist * side)
    let body = if s.horizontal-labels or calc.abs(angle) < 0.1deg { lb.body } else {
      rotate(angle, reflow: false, lb.body)
    }
    items.push((x: cx - w / 2, y: cy - h / 2, body: body))
    let ext = if s.horizontal-labels { (w / 2, h / 2) } else { let e = calc.max(w, h) / 2; (e, e) }
    bounds.push((x0: cx - ext.at(0), y0: cy - ext.at(1), x1: cx + ext.at(0), y1: cy + ext.at(1)))
  }
  (items: items, bounds: bounds)
}
