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

// --- Paths: straight lines and bent curves ----------------------------------

#let _lerp(a, b, t) = (a.at(0) + (b.at(0) - a.at(0)) * t, a.at(1) + (b.at(1) - a.at(1)) * t)

/// Blossom of a cubic Bézier curve: `_blossom(p, t, t, t)` is the point at
/// `t`, and the control points of the part between `t0` and `t1` are
/// `(t0, t0, t0)`, `(t0, t0, t1)`, `(t0, t1, t1)`, `(t1, t1, t1)`.
#let _blossom(p, u, v, w) = {
  let l1 = (_lerp(p.at(0), p.at(1), u), _lerp(p.at(1), p.at(2), u), _lerp(p.at(2), p.at(3), u))
  let l2 = (_lerp(l1.at(0), l1.at(1), v), _lerp(l1.at(1), l1.at(2), v))
  _lerp(l2.at(0), l2.at(1), w)
}

#let _samples = 64

/// The path of a leader from `p0` to `p1`: a straight line, or with `bend`
/// a cubic curve leaving `p0` turned by `bend` to the left of the chord and
/// reaching `p1` symmetrically (TikZ's `bend left`, with its control points
/// at 0.39 times the chord).
#let _path(p0, p1, bend) = {
  let (dx, dy) = (p1.at(0) - p0.at(0), p1.at(1) - p0.at(1))
  let l = _len(dx, dy)
  let (ux, uy) = (dx / l, dy / l)
  if bend == 0deg { return (bez: none, p0: p0, u: (ux, uy), length: l) }
  let (nx, ny) = (uy, -ux)
  let (co, si) = (calc.cos(bend), calc.sin(bend))
  let d = 0.3915 * l
  let c0 = (p0.at(0) + (ux * co + nx * si) * d, p0.at(1) + (uy * co + ny * si) * d)
  let c1 = (p1.at(0) + (-ux * co + nx * si) * d, p1.at(1) + (-uy * co + ny * si) * d)
  let bez = (p0, c0, c1, p1)
  // Arc length, sampled.
  let pts = range(_samples + 1).map(k => _blossom(bez, k / _samples, k / _samples, k / _samples))
  let cum = (0pt,)
  for k in range(_samples) {
    let (a, b) = (pts.at(k), pts.at(k + 1))
    cum.push(cum.last() + _len(b.at(0) - a.at(0), b.at(1) - a.at(1)))
  }
  (bez: bez, pts: pts, cum: cum, length: cum.last())
}

/// Curve parameter at arc length `a`.
#let _t-at(path, a) = {
  if a <= 0pt { return 0 }
  if a >= path.length { return 1 }
  let k = path.cum.position(c => c >= a)
  let (c0, c1) = (path.cum.at(k - 1), path.cum.at(k))
  let f = if c1 == c0 { 0 } else { (a - c0) / (c1 - c0) }
  (k - 1 + f) / _samples
}

/// Point at arc length `a`.
#let _point(path, a) = {
  if path.bez == none { return (path.p0.at(0) + path.u.at(0) * a, path.p0.at(1) + path.u.at(1) * a) }
  let t = _t-at(path, a)
  _blossom(path.bez, t, t, t)
}

/// Unit direction of the chord from arc length `a` to arc length `b`.
#let _dir(path, a, b) = {
  if path.bez == none { return path.u }
  let (p, q) = (_point(path, a), _point(path, b))
  let (dx, dy) = (q.at(0) - p.at(0), q.at(1) - p.at(1))
  let l = _len(dx, dy)
  if l == 0pt { path.u } else { (dx / l, dy / l) }
}

/// Draws a leader from `p0` to `p1`.
///
/// `s` is a dictionary with `fill`, `stroke` (`auto` for round dots), `radius`,
/// `spacing`, `shorten-start`, `shorten-end`, `marks`, `above`, `below`,
/// `middle`, `horizontal-labels`, `label-fill` and optionally `bend` (an
/// angle); lengths already absolute. Returns `(items, bounds)`.
#let leader-items(p0, p1, s) = {
  let items = ()
  let bounds = ()
  let (dx, dy) = (p1.at(0) - p0.at(0), p1.at(1) - p0.at(1))
  let l = _len(dx, dy)
  if l < 1pt or l > 500cm { return (items: (), bounds: ()) }
  let path = _path(p0, p1, s.at("bend", default: 0deg))
  let L = path.length
  let (s0, s1) = (s.shorten-start, s.shorten-end)
  let r = s.radius
  let m = s.marks
  let size = s.at("mark-size", default: 4pt)
  let (head0, head1) = (m in ("<-", "<->"), m in ("->", "<->"))
  // Arrow heads take the colour of the line.
  let paint = if s.stroke == auto { s.fill } else {
    let p = stroke(s.stroke).paint
    if p == auto { s.fill } else { p }
  }

  if s.stroke == auto {
    // Round dots, spaced evenly and centred on the line (nicematrix's
    // "standard" style), at equal distances along a curve.
    let n = calc.floor((L - s0 - s1) / s.spacing)
    if n >= 0 {
      let off = (L - s.spacing * n + s0 - s1) / 2
      for k in range(n + 1) {
        let (cx, cy) = _point(path, off + s.spacing * k)
        items.push((x: cx - r, y: cy - r, body: circle(radius: r, fill: s.fill, stroke: none)))
        bounds.push((x0: cx - r, y0: cy - r, x1: cx + r, y1: cy + r))
      }
    }
  } else {
    // The line stops inside an arrow head, so that its cap does not show.
    let a = s0 + if head0 { size / 2 } else { 0pt }
    let b = L - s1 - if head1 { size / 2 } else { 0pt }
    if b > a {
      let st = s.stroke
      let w = stroke(st).thickness
      let w = if w == auto { 1pt } else { w.to-absolute() }
      if path.bez == none {
        let (ax, ay) = _point(path, a)
        let (bx, by) = _point(path, b)
        items.push((x: ax, y: ay, body: line(start: (0pt, 0pt), end: (bx - ax, by - ay), stroke: st)))
        bounds.push((x0: calc.min(ax, bx), y0: calc.min(ay, by), x1: calc.max(ax, bx), y1: calc.max(ay, by)))
      } else {
        let (ta, tb) = (_t-at(path, a), _t-at(path, b))
        let q = (
          _blossom(path.bez, ta, ta, ta), _blossom(path.bez, ta, ta, tb),
          _blossom(path.bez, ta, tb, tb), _blossom(path.bez, tb, tb, tb),
        )
        let (ox, oy) = q.at(0)
        let rel(p) = (p.at(0) - ox, p.at(1) - oy)
        items.push((x: ox, y: oy, body: curve(stroke: st,
          curve.move(rel(q.at(0))), curve.cubic(rel(q.at(1)), rel(q.at(2)), rel(q.at(3))))))
        let pts = range(17).map(k => _point(path, a + (b - a) * k / 16))
        bounds.push((
          x0: calc.min(..pts.map(p => p.at(0))) - w / 2, y0: calc.min(..pts.map(p => p.at(1))) - w / 2,
          x1: calc.max(..pts.map(p => p.at(0))) + w / 2, y1: calc.max(..pts.map(p => p.at(1))) + w / 2,
        ))
      }
    }
  }

  // Arrow tips, along the last part of the path.
  if head1 {
    let (x, y) = _point(path, L - s1)
    let (ux, uy) = _dir(path, L - s1 - size, L - s1)
    let a = _arrow(x, y, ux, uy, size, paint)
    items.push(a.item); bounds.push(a.bound)
  }
  if head0 {
    let (x, y) = _point(path, s0)
    let (ux, uy) = _dir(path, s0 + size, s0)
    let a = _arrow(x, y, ux, uy, size, paint)
    items.push(a.item); bounds.push(a.bound)
  }

  // Labels: `above`, `below` and `middle` (nicematrix's `^`, `_` and `:`),
  // at the middle of the path.
  let (mx, my) = _point(path, L / 2)
  let (tx, ty) = _dir(path, L / 2 - 0.5pt, L / 2 + 0.5pt)
  let angle = calc.atan2(tx, ty)
  // Keep the text upright.
  if angle > 90deg + 0.1deg or angle < -90deg + 0.1deg { angle += 180deg }
  let (nx, ny) = (ty, -tx)
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
