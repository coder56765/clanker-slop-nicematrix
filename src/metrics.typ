/// Measuring and placing math content with exact ascents and descents.
///
/// Inline equations report adjusted edges (they take `text.top-edge` /
/// `bottom-edge` into account and subtract a "slack" derived from the
/// leading), so we never rely on their natural size. Instead we give the
/// equation huge fixed edges on one side and the ink bounds on the other,
/// which yields the exact ascent or descent of the math frame. For placing,
/// both edges are huge and fixed, so the baseline is at a known offset.
/// All functions here must be called in a context.

#let BIG = 5000pt

/// The math style a `nicemat` is in, as a level: 0 display, 1 text (an
/// inline equation), 2 script, 3 script-script. `nicemat-setup` marks inline
/// equations with level 1, and the cells of a matrix at level `k ≥ 1` carry
/// the level of their style. The level is stored in the supplement of
/// equations, which is never shown for inline ones.
#let level-flag(k) = metadata((nicematrix-math-level: k))
#let inline-flag = level-flag(1)

/// The level of the current context (0 when not marked). Must be called in
/// a context.
#let math-level() = {
  let s = math.equation.supplement
  if type(s) == content and s.func() == metadata and type(s.value) == dictionary and "nicematrix-math-level" in s.value {
    s.value.nicematrix-math-level
  } else { 0 }
}

/// `body` in the math style of a level.
#let style-at(level, body, cramped: true) = {
  if level <= 1 { math.inline(body, cramped: cramped) }
  else if level == 2 { math.script(body, cramped: cramped) }
  else { math.sscript(body, cramped: cramped) }
}

/// The styles of a matrix at `level`: its own (`matrix`) and that of its
/// cells (`cells`: one level smaller, like the cells of `mat`). `flag`:
/// whether the cells must carry their level.
///
/// Note: inside script styles, `text.size` keeps the size of the equation
/// (only `em` is scaled), so explicit styles in new equations are exact.
#let math-style(level) = {
  let cells = if level == 0 { 1 } else { calc.min(level + 1, 3) }
  (matrix: level, cells: cells, flag: level >= 1)
}

/// The equation used for a cell: text style (like LaTeX's matrices, and like
/// Typst's `mat` in a display equation) or script style with `small`.
/// The text edges are restored inside so that text in cells is unaffected by
/// the edges we set outside.
/// With `style` (from `math-style`), the cells take the style of the cells
/// of a matrix at that level, and carry that level.
#let cell-eq(body, small: false, style: none) = {
  let (te, be) = (text.top-edge, text.bottom-edge)
  if style != none {
    return math.equation(block: false, {
      set text(top-edge: te, bottom-edge: be)
      if style.flag {
        set math.equation(supplement: level-flag(style.cells))
        style-at(style.cells, body)
      } else {
        style-at(style.cells, body)
      }
    })
  }
  math.equation(block: false, {
    set text(top-edge: te, bottom-edge: be)
    if small { math.script(body, cramped: true) } else { math.inline(body, cramped: true) }
  })
}

/// An equation with `body` in the style of the matrix itself.
#let matrix-eq(body, style: none) = {
  if style == none or style.matrix <= 1 { return math.equation(body) }
  math.equation(style-at(style.matrix, body, cramped: false))
}

/// Plain math equation (no style change) with restored edges.
#let eq(body) = cell-eq(body, small: false)

/// Width, ascent and descent of an inline equation (or any inline content).
#let ink(e) = (
  w: measure(box(e)).width,
  a: measure(box(text(top-edge: "bounds", bottom-edge: -BIG, e))).height - BIG,
  d: measure(box(text(top-edge: BIG, bottom-edge: "bounds", e))).height - BIG,
)

/// Content to `place` at `dy = baseline - BIG`: its baseline lands on the
/// requested line.
#let placeable(e) = box(text(top-edge: BIG, bottom-edge: -BIG, e))

/// Font metrics used by the layout.
/// With `style`, the paren strut and the axis of the cells follow the style
/// of the cells, and the axis of the matrix its own style.
#let math-metrics(small: false, style: none) = {
  let at(level, body) = if style == none {
    math.equation(if level == 2 { math.script(body) } else { body })
  } else {
    math.equation(style-at(level, body, cramped: false))
  }
  let (lm, lc) = if style == none { (1, if small { 2 } else { 1 }) } else { (style.matrix, style.cells) }
  let paren = ink(at(lc, [(]))
  // The math axis, exactly as Typst uses it for matrices: a `vec` centres
  // its body on the axis.
  let probe(level) = ink(at(level, math.vec(delim: none, box(height: 100pt, baseline: 50pt)))).a - 50pt
  (
    paren-a: paren.a,
    paren-d: paren.d,
    axis: probe(lm),
    cell-axis: probe(lc),
    em: 1em.to-absolute(),
  )
}

/// A stretched delimiter (one side) sized like the delimiters of `mat` for a
/// body of height `h`. Returns the equation and its metrics; the glyph is
/// centred on the math axis, so place its baseline at `centre + axis`.
/// Delimiters that `vec` (and `mat`) accept; any other character (an arrow,
/// …) is stretched with `math.stretch`, as nicematrix accepts any extensible
/// delimiter.
#let _vec-delims = (
  "(", ")", "[", "]", "{", "}", "|", "‖", "⟨", "⟩", "⌊", "⌋", "⌈", "⌉", "⟦", "⟧",
  "⟮", "⟯", "⦇", "⦈", "⦃", "⦄", "⟬", "⟭", "⦅", "⦆", "⌜", "⌝", "⌞", "⌟", "⟅", "⟆",
  "/", "\\", "⎰", "⎱", "⟪", "⟫", "⧼", "⧽",
)

#let delim-glyph(d, h, side: left, fill: auto, tr: none, br: none, style: none) = {
  let v = if str(d) in _vec-delims {
    let pair = if side == left { (d, none) } else { (none, d) }
    // The body box must be at least as tall as the paren strut `vec` pads to.
    math.vec(delim: pair, box(width: 0pt, height: h, baseline: h * 0.25))
  } else {
    // Same target height as `mat`: 110% of the body, centred on the axis.
    math.stretch(symbol(str(d)), size: h * 1.1)
  }
  if tr != none or br != none { v = math.attach(v, tr: tr, br: br) }
  let e = matrix-eq(v, style: style)
  if fill != auto and fill != none { e = text(fill: fill, e) }
  let m = ink(e)
  (body: e, w: m.w, a: m.a, d: m.d)
}
