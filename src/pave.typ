/// Paths along the grid lines and flood fills, in the style of the pavemat
/// package.
///
/// A path is a string of directions starting from a grid point: `W` (up),
/// `A` (left), `S` (down), `D` (right). An upper-case letter draws the
/// segment, a lower-case one only moves (the segment still separates the
/// regions of `flood`). A group `(paint: red, thickness: 2pt)` changes the
/// stroke of the following segments, up to the matching `]`.
///
/// Grid points and lines are numbered within the main block, like the rules:
/// the point `(i, j)` is at the crossing of the rule `i` (above the row `i`)
/// and of the rule `j` (left of the column `j`).

#import "util.typ": plain-text, to-coord, to-int, norm-index, merge-stroke

#let _default-chars = (up: "W", down: "S", left: "A", right: "D")

/// The segments of a `pave` marker: `(dir: "h" | "v", k, t, stroke, hidden)`.
/// A segment `h` lies on the rule `k` between the column rules `t` and `t + 1`;
/// a segment `v` on the column rule `k` between the rules `t` and `t + 1`.
/// `nR` and `nC` are the numbers of rows and columns of the main block.
#let pave-segments(p, nR, nC, base-stroke) = {
  let chars = _default-chars + p.at("chars", default: (:))
  let dirs = (:)
  for (name, ch) in chars { dirs.insert(upper(str(ch)), name) }
  let path = if type(p.path) == str { p.path } else { plain-text(p.path) }
  let path = path.replace("'", "\"")

  let from = p.at("from", default: top + left)
  let (i, j) = if type(from) == alignment {
    (if from.y == bottom { nR } else { 0 }, if from.x == right { nC } else { 0 })
  } else {
    let (a, b) = to-coord(from, name: "from")
    (norm-index(a, nR + 1), norm-index(b, nC + 1))
  }

  let stack = (merge-stroke(base-stroke, p.at("stroke", default: auto)),)
  let segs = ()
  let cs = path.clusters()
  let k = 0
  while k < cs.len() {
    let c = cs.at(k)
    if c == "(" {
      let close = cs.slice(k).position(x => x == ")")
      if close == none { panic("nicematrix: unclosed `(` in the path " + repr(path)) }
      let spec = eval(cs.slice(k, k + close + 1).join())
      stack.push(merge-stroke(stack.last(), spec))
      k += close + 1
      continue
    }
    if c == "[" or c.trim() == "" { k += 1; continue }
    if c == "]" {
      if stack.len() > 1 { let _ = stack.pop() }
      k += 1
      continue
    }
    let name = dirs.at(upper(c), default: none)
    if name == none { panic("nicematrix: unknown direction " + repr(c) + " in the path " + repr(path)) }
    let hidden = c != upper(c)
    let st = stack.last()
    let (ni, nj) = if name == "up" { (i - 1, j) } else if name == "down" { (i + 1, j) }
      else if name == "left" { (i, j - 1) } else { (i, j + 1) }
    let seg = if name == "right" { (dir: "h", k: i, t: j) }
      else if name == "left" { (dir: "h", k: i, t: j - 1) }
      else if name == "down" { (dir: "v", k: j, t: i) }
      else { (dir: "v", k: j, t: i - 1) }
    let inside = if seg.dir == "h" { seg.k >= 0 and seg.k <= nR and seg.t >= 0 and seg.t < nC }
      else { seg.k >= 0 and seg.k <= nC and seg.t >= 0 and seg.t < nR }
    if inside { segs.push(seg + (stroke: st, hidden: hidden)) }
    (i, j) = (ni, nj)
    k += 1
  }
  segs
}

/// Merges consecutive collinear segments with the same style, so that dash
/// patterns run continuously along a straight part of a path.
#let merge-segments(segs) = {
  let out = ()
  for s in segs {
    let s = s + (t0: s.t, t1: s.t)
    if out.len() > 0 {
      let l = out.last()
      let same-line = l.dir == s.dir and l.k == s.k and l.stroke == s.stroke and l.hidden == s.hidden
      if same-line and (s.t == l.t1 + 1 or s.t == l.t0 - 1) {
        out.at(-1) = l + (t0: calc.min(l.t0, s.t), t1: calc.max(l.t1, s.t))
        continue
      }
    }
    out.push(s)
  }
  out
}

/// The cells (main-based `(i, j)`) connected to `start` without crossing a
/// segment of a path (drawn or hidden).
#let flood-cells(start, nR, nC, segs) = {
  let fence = (:)
  for s in segs { fence.insert(s.dir + str(s.k) + "," + str(s.t), true) }
  let blocked(dir, k, t) = (dir + str(k) + "," + str(t)) in fence
  let seen = (:)
  let key(i, j) = str(i) + "," + str(j)
  let stack = (start,)
  seen.insert(key(..start), true)
  let cells = ()
  while stack.len() > 0 {
    let (i, j) = stack.pop()
    cells.push((i, j))
    let moves = (
      ((i + 1, j), blocked("h", i + 1, j)),
      ((i - 1, j), blocked("h", i, j)),
      ((i, j + 1), blocked("v", j + 1, i)),
      ((i, j - 1), blocked("v", j, i)),
    )
    for ((ni, nj), b) in moves {
      if b or ni < 0 or nj < 0 or ni >= nR or nj >= nC or key(ni, nj) in seen { continue }
      seen.insert(key(ni, nj), true)
      stack.push((ni, nj))
    }
  }
  cells
}
