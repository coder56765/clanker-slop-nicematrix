/// Small helpers shared by the whole package: coercions of values coming
/// from math-mode calls, coordinate parsing, delimiter pairing and strokes.

/// Best-effort plain text of a value. Math-mode arguments arrive as content
/// (`span: 3` gives `[3]`, `(0, 1)` gives an `lr` element), so most coercions
/// go through this.
#let plain-text(it) = {
  let t = type(it)
  if it == none { return "" }
  if t == str { return it }
  if t == symbol { return str(it) }
  if t == int or t == float { return str(it) }
  if t != content { return "" }
  if it.has("text") { return plain-text(it.text) }
  if it.has("children") { return (("",) + it.children.map(plain-text)).join("") }
  if it.has("body") { return plain-text(it.body) }
  if it.has("child") { return plain-text(it.child) }
  if it.func() == [ ].func() { return " " }
  ""
}

/// Normalizes the minus signs and spaces of a number typed in math mode.
#let _clean-number(s) = s.replace("−", "-").replace(" ", "").trim()

/// Coerces an int, a float, a string or math content (`[3]`) to an integer.
#let to-int(v, name: "value") = {
  let t = type(v)
  if t == int { return v }
  if t == float { return int(v) }
  let s = _clean-number(plain-text(v))
  if s.match(regex("^-?\d+$")) == none {
    panic("nicematrix: expected an integer for `" + name + "`, got " + repr(v))
  }
  int(s)
}

/// Coerces a length-like value; content such as `[2pt]` is not supported in
/// math mode, so we only accept real lengths here (with a helpful message).
#let to-length(v, name: "value") = {
  let t = type(v)
  if t == length or t == relative or t == ratio { return v }
  if t == int or t == float { return v * 1pt }
  panic("nicematrix: expected a length for `" + name + "` (write `#2pt` in math mode), got " + repr(v))
}

/// Coerces a boolean; math mode gives content for bare `true`.
#let to-bool(v, name: "value") = {
  if type(v) == bool { return v }
  let s = plain-text(v).trim()
  if s == "true" { return true }
  if s == "false" { return false }
  panic("nicematrix: expected a boolean for `" + name + "` (write `#true` in math mode), got " + repr(v))
}

/// Coerces an angle; plain numbers (also math content such as `30` or
/// `−30`) are degrees.
#let to-angle(v, name: "value") = {
  let t = type(v)
  if t == angle { return v }
  if t == int or t == float { return v * 1deg }
  let s = _clean-number(plain-text(v)).replace("deg", "").replace("°", "")
  if s.match(regex("^-?\d+(\.\d+)?$")) == none {
    panic("nicematrix: expected an angle for `" + name + "` (such as `30` or `#30deg`), got " + repr(v))
  }
  float(s) * 1deg
}

/// Coerces an integer or a list of integers: an array, or math content such
/// as `(1, −1)` or `2`.
#let to-int-list(v, name: "value") = {
  if type(v) == array { return v.map(x => to-int(x, name: name)) }
  if type(v) in (int, float) { return (to-int(v, name: name),) }
  let s = _clean-number(plain-text(v)).replace("(", "").replace(")", "")
  s.split(",").filter(p => p != "").map(p => to-int(p, name: name))
}

/// Parses a cell coordinate `(row, col)`.
///
/// Accepts an array `(1, 2)`, math content `(1, 2)` (an `lr` element), a
/// string `"1-2"`, `"1,2"` or `"(1, 2)"`, or a dictionary `(row: 1, col: 2)`.
/// Negative numbers are kept as is (they count from the end).
#let to-coord(v, name: "coordinate") = {
  let t = type(v)
  if t == array {
    if v.len() != 2 { panic("nicematrix: `" + name + "` needs two numbers, got " + repr(v)) }
    return v.map(x => to-int(x, name: name))
  }
  if t == dictionary {
    let r = v.at("row", default: v.at("i", default: none))
    let c = v.at("col", default: v.at("j", default: none))
    if r == none or c == none { panic("nicematrix: `" + name + "` dictionary needs `row` and `col`") }
    return (to-int(r, name: name), to-int(c, name: name))
  }
  let s = _clean-number(plain-text(v)).replace("(", "").replace(")", "")
  let parts = if s.contains(",") { s.split(",") } else if s.contains(";") { s.split(";") } else {
    // "1-2" style (only without negative numbers)
    let m = s.match(regex("^(\d+)-(\d+)$"))
    if m == none { () } else { m.captures }
  }
  if parts.len() != 2 {
    panic("nicematrix: cannot read `" + name + "` from " + repr(v) + " (use `(row, col)`)")
  }
  parts.map(p => to-int(p, name: name))
}

/// Resolves a possibly negative index against `n` (count from the end).
#let norm-index(k, n) = if k < 0 { n + k } else { k }

/// Resolves a length, relative length or ratio to an absolute length. Must be
/// called in a context. Ratios have no sensible base here and count as zero.
#let abs-len(v) = {
  let t = type(v)
  if t == length { v.to-absolute() }
  else if t == relative { v.length.to-absolute() }
  else if t == ratio { 0pt }
  else if t == int or t == float { v * 1pt }
  else if v == none { 0pt }
  else { panic("nicematrix: expected a length, got " + repr(v)) }
}

/// Returns element `k` of a per-gap specification: either a single value or
/// an array whose last entry is repeated.
#let pick(spec, k) = {
  if type(spec) != array { return spec }
  if spec.len() == 0 { return none }
  spec.at(calc.min(k, spec.len() - 1))
}

/// Normalizes a length or a dictionary with `left/right/top/bottom/x/y/rest`
/// keys into a dictionary with the four sides.
#let sides(v, default: 0pt) = {
  if type(v) != dictionary {
    let x = if v == auto or v == none { default } else { v }
    return (left: x, right: x, top: x, bottom: x)
  }
  let rest = v.at("rest", default: default)
  let x = v.at("x", default: rest)
  let y = v.at("y", default: rest)
  (
    left: v.at("left", default: x),
    right: v.at("right", default: x),
    top: v.at("top", default: y),
    bottom: v.at("bottom", default: y),
  )
}

/// Closing delimiter matching an opening one (the same pairing Typst uses).
#let _closing = (
  "(": ")", "[": "]", "{": "}", "⟨": "⟩", "⟦": "⟧", "⌈": "⌉", "⌊": "⌋",
  "|": "|", "‖": "‖", "⦇": "⦈", "⦃": "⦄", "⟮": "⟯", "⟬": "⟭",
  "⦅": "⦆", "⌜": "⌝", "⌞": "⌟", "⟅": "⟆", "/": "\\", "\\": "/",
)

/// Splits a `delim` specification (`"("`, a symbol, an array or `none`)
/// into a `(left, right)` pair; each side may be `none`.
#let delim-pair(d) = {
  if d == none { return (none, none) }
  if type(d) == array {
    if d.len() != 2 { panic("nicematrix: `delim` array needs two entries, got " + repr(d)) }
    return (d.at(0), d.at(1))
  }
  let s = str(d)
  let r = _closing.at(s, default: s)
  (d, if type(d) == str { r } else if r == s { d } else { r })
}

/// Merges a user stroke specification into a default dictionary stroke.
/// `auto` keeps the default, `none` disables, a color/length/dictionary/
/// stroke is layered on top of the default.
#let merge-stroke(default, user) = {
  if user == auto { return default }
  if user == none { return none }
  let base = if type(default) == dictionary { default } else { (:) }
  let t = type(user)
  if t == color or t == gradient or t == tiling { return base + (paint: user) }
  if t == length { return base + (thickness: user) }
  // The rules default to square caps (like the `augment` of `mat`), which
  // would merge the dots of a dotted pattern into a solid line: those get
  // Typst's default butt caps back unless a cap is given.
  let round-dots(d, user-cap) = {
    let dotted = d.at("dash", default: none) in ("dotted", "densely-dotted", "loosely-dotted")
    if dotted and user-cap == auto and d.at("cap", default: auto) == "square" { d + (cap: "butt") } else { d }
  }
  if t == dictionary { return round-dots(base + user, user.at("cap", default: auto)) }
  if t == stroke {
    let d = base
    let fields = (
      paint: user.paint, thickness: user.thickness, cap: user.cap,
      join: user.join, dash: user.dash, miter-limit: user.miter-limit,
    )
    for (key, v) in fields {
      if v != auto { d.insert(key, v) }
    }
    return round-dots(d, user.cap)
  }
  panic("nicematrix: invalid stroke " + repr(user))
}

/// Like `merge-stroke`, but also accepts a dictionary of sides (`top`,
/// `bottom`, `left`, `right`, `x`, `y`, `rest`) as `rect` does; `true`
/// means the default stroke.
#let side-stroke(default, user) = {
  if user == true { return default }
  let sides = ("top", "bottom", "left", "right", "x", "y", "rest")
  if type(user) == dictionary and user.keys().any(k => k in sides) {
    return user.pairs().map(((k, v)) => (k, if v == none { none } else { merge-stroke(default, if v == true { auto } else { v }) })).to-dict()
  }
  merge-stroke(default, user)
}

/// Thickness of a (dictionary) stroke, for offsets of double rules.
#let stroke-thickness(s) = {
  if s == none { return 0pt }
  let st = stroke(s)
  if st.thickness == auto { 1pt } else { st.thickness.to-absolute() }
}

/// Text-mode representation of horizontal alignment components.
#let h-align(a, fallback: center) = {
  if a == auto or a == none { return fallback }
  let x = if type(a) == alignment and a.x != none { a.x } else if type(a) == alignment and a.y == none { a } else { fallback }
  if x == start { if text.dir == rtl { right } else { left } }
  else if x == end { if text.dir == rtl { left } else { right } }
  else { x }
}

#let v-align(a, fallback: horizon) = {
  if type(a) == alignment and a.y != none { a.y } else if type(a) == alignment and a.x == none { a } else { fallback }
}

/// Offset of an object of width `w` aligned inside a slot of width `total`.
#let align-offset(a, total, w) = {
  if a == left { 0pt } else if a == right { total - w } else { (total - w) / 2 }
}
