/// Groups of matrices sharing their column widths, like nicematrix's
/// `{NiceMatrixBlock}` with `auto-columns-width`.
///
/// Each `nicemat` inside a group publishes the natural widths of its columns
/// and delimiters in a `metadata`; all members then use the maxima (Typst's
/// introspection converges in two layout iterations).

#let group-state = state("nicematrix-group", none)
#let group-counter = counter("nicematrix-group")

/// Makes all the `nicemat` inside `body` use the same column widths, so that
/// stacked matrices have their columns aligned.
#let nicemat-group(body) = {
  group-counter.step()
  context {
    let id = group-counter.get().first()
    group-state.update(id)
    body
    group-state.update(none)
  }
}

/// The widths shared by the group `id`: `(cols: array, delims: (l, r))`, or
/// `none` when no matrix of the group has been laid out yet.
#let group-widths(id) = {
  let ms = query(<nicematrix-group>).filter(m => m.value.group == id).map(m => m.value)
  if ms.len() == 0 { return none }
  let n = calc.max(..ms.map(m => m.cols.len()))
  (
    cols: range(n).map(k => calc.max(0pt, ..ms.map(m => m.cols.at(k, default: 0pt)))),
    delims: (calc.max(..ms.map(m => m.delims.at(0))), calc.max(..ms.map(m => m.delims.at(1)))),
  )
}
