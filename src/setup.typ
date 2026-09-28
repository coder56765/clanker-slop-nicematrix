/// Document-level setup: `#show: nicemat-setup`.

#import "metrics.typ": inline-flag
#import "nicemat.typ": nicemat

/// Makes every `nicemat` in an inline equation follow the size of `mat`
/// there (script-size cells, like Typst's inline matrices). Nested `nicemat`
/// in the cells of another one shrink as nested `mat` do.
///
/// With `mat: true`, every `mat` of the document is also drawn by `nicemat`
/// (`show math.mat: nicemat`).
///
/// ```typ
/// #show: nicemat-setup
/// #show: nicemat-setup.with(mat: true)
/// ```
#let nicemat-setup(body, mat: false) = {
  show math.equation.where(block: false): set math.equation(supplement: inline-flag)
  if mat {
    show math.mat: nicemat
    body
  } else {
    body
  }
}
