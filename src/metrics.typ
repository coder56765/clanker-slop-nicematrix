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

/// The equation used for a cell: text style (like LaTeX's matrices, and like
/// Typst's `mat` in a display equation) or script style with `small`.
/// The text edges are restored inside so that text in cells is unaffected by
/// the edges we set outside.
#let cell-eq(body, small: false) = {
  let (te, be) = (text.top-edge, text.bottom-edge)
  math.equation(block: false, {
    set text(top-edge: te, bottom-edge: be)
    if small { math.script(body, cramped: true) } else { math.inline(body, cramped: true) }
  })
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
#let math-metrics(small: false) = {
  let wrap = if small { math.script } else { x => x }
  let paren = ink(math.equation(wrap([(])))
  // The math axis, exactly as Typst uses it for matrices: a `vec` centres
  // its body on the axis.
  let probe(style) = ink(math.equation(style(math.vec(delim: none, box(height: 100pt, baseline: 50pt))))).a - 50pt
  (
    paren-a: paren.a,
    paren-d: paren.d,
    axis: probe(x => x),
    cell-axis: probe(wrap),
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

#let delim-glyph(d, h, side: left, fill: auto, tr: none, br: none) = {
  let v = if str(d) in _vec-delims {
    let pair = if side == left { (d, none) } else { (none, d) }
    // The body box must be at least as tall as the paren strut `vec` pads to.
    math.vec(delim: pair, box(width: 0pt, height: h, baseline: h * 0.25))
  } else {
    // Same target height as `mat`: 110% of the body, centred on the axis.
    math.stretch(symbol(str(d)), size: h * 1.1)
  }
  if tr != none or br != none { v = math.attach(v, tr: tr, br: br) }
  let e = math.equation(v)
  if fill != auto and fill != none { e = text(fill: fill, e) }
  let m = ink(e)
  (body: e, w: m.w, a: m.a, d: m.d)
}
