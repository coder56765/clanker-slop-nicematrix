// `nicemat` must reproduce the geometry of `mat` (in a display equation)
// for plain matrices.
#import "/nicematrix.typ": *

#set page(width: auto, height: auto, margin: 1em)

#let tol = 0.05pt
#let check(name, a, b) = context {
  let (ma, mb) = (_ink(math.equation(math.display(a))), _ink(math.equation(b)))
  let ok = calc.abs(ma.w - mb.w) < tol and calc.abs(ma.a - mb.a) < tol and calc.abs(ma.d - mb.d) < tol
  assert(ok, message: name + ": mat " + repr(ma) + " vs nicemat " + repr(mb))
  [#name: #math.equation(block: false, math.display(a)) vs #math.equation(block: false, b) ✓ \ ]
}

#check("2x2", $mat(1, 2; 3, 4)$, $nicemat(1, 2; 3, 4)$)
#check("fractions", $mat(frac(1, 2), -frac(1, 2); frac(1, 3), frac(1, 4))$, $nicemat(frac(1, 2), -frac(1, 2); frac(1, 3), frac(1, 4))$)
#check("brackets", $mat(delim: "[", a, b, c; d, e, f)$, $nicemat(delim: "[", a, b, c; d, e, f)$)
#check("no delim", $mat(delim: #none, x^2, y; z, w_1)$, $nicemat(delim: #none, x^2, y; z, w_1)$)
#check("bars", $mat(delim: "|", 1, 0; 0, 1)$, $nicemat(delim: "|", 1, 0; 0, 1)$)
#check("braces", $mat(delim: "{", 1; 2; 3; 4)$, $nicemat(delim: "{", 1; 2; 3; 4)$)
#check("align right", $mat(align: #right, 1, 200; 300, 4)$, $nicemat(align: #right, 1, 200; 300, 4)$)
#check("gaps", $mat(row-gap: #1em, column-gap: #2em, 1, 2; 3, 4)$, $nicemat(row-gap: #1em, column-gap: #2em, 1, 2; 3, 4)$)
#check("double bars", $mat(delim: "‖", 1, 0; 0, 1)$, $nicemat(delim: "‖", 1, 0; 0, 1)$)
#check("chevrons", $mat(delim: #sym.chevron.l, 1, 0; 0, 1)$, $nicemat(delim: #sym.chevron.l, 1, 0; 0, 1)$)
#check("mixed pair", $mat(delim: #("[", ")"), 1, 0; 0, 1)$, $nicemat(delim: #("[", ")"), 1, 0; 0, 1)$)
#check("floor", $mat(delim: "⌊", 1, 0; 0, 1)$, $nicemat(delim: "⌊", 1, 0; 0, 1)$)
#check("single", $mat(x)$, $nicemat(x)$)
#check("row", $mat(1, 2, 3)$, $nicemat(1, 2, 3)$)
#check("tall", $mat(sum_(i=1)^n a_i, 0; 0, integral_0^1 f)$, $nicemat(sum_(i=1)^n a_i, 0; 0, integral_0^1 f)$)
#check("dots kept", $mat(1, dots.c, 1; dots.v, dots.down, dots.v; 1, dots.c, 1)$, $nicemat(dots: #(symbols: false), 1, dots.c, 1; dots.v, dots.down, dots.v; 1, dots.c, 1)$)

// `show math.mat: nicemat` keeps the geometry.
#let plain = $mat(1, 2; 3, frac(4, 5))$
#let before = state("before")
#context before.update(_ink(math.equation(math.display(plain))))
#[
  #show math.mat: nicemat
  #context {
    let after = _ink(math.equation(math.display(plain)))
    let b = before.get()
    assert(calc.abs(b.w - after.w) < tol and calc.abs(b.a - after.a) < tol, message: "show rule: " + repr(b) + " vs " + repr(after))
    [show rule: #math.equation(block: false, math.display(plain)) ✓]
  }
]

// `set math.mat(delim: "[")` is inherited.
#[
  #set math.mat(delim: "[")
  #check("inherit delim", $mat(1, 2; 3, 4)$, $nicemat(1, 2; 3, 4)$)
]

$ A = nicemat(1, 2; 3, 4) quad B = mat(1, 2; 3, 4) quad C = nicemat(frac(1, 2), x; y^2, z) $

// Under `nicemat-setup`, inline matrices follow `mat` in inline equations
// (script-size cells), and display ones are unchanged.
#[
  #show: nicemat-setup
  #let check-inline(name, a, b) = context {
    let (ma, mb) = (_ink(math.equation(a)), _ink(math.equation(b)))
    let ok = calc.abs(ma.w - mb.w) < tol and calc.abs(ma.a - mb.a) < tol and calc.abs(ma.d - mb.d) < tol
    assert(ok, message: name + ": inline mat " + repr(ma) + " vs nicemat " + repr(mb))
    [#name: #a vs #b ✓ \ ]
  }
  #check-inline("inline 2x2", $mat(1, 2; 3, 4)$, $nicemat(1, 2; 3, 4)$)
  #check-inline("inline fractions", $mat(frac(1, 2), x; y^2, z)$, $nicemat(frac(1, 2), x; y^2, z)$)
  #check-inline("inline brackets", $mat(delim: "[", a, b, c; d, e, f)$, $nicemat(delim: "[", a, b, c; d, e, f)$)
  #check-inline("inline dots kept", $mat(1, dots.c, 1; dots.v, dots.down, dots.v; 1, dots.c, 1)$, $nicemat(dots: #(symbols: false), 1, dots.c, 1; dots.v, dots.down, dots.v; 1, dots.c, 1)$)
  #check-inline("inline nested", $mat(mat(1, 2; 3, 4), 0; 0, 1)$, $nicemat(nicemat(1, 2; 3, 4), 0; 0, 1)$)
  #check("forced display", $mat(1, 2; 3, 4)$, $nicemat(1, 2; 3, 4, small: #false)$)

  // In display equations, the geometry is read from the real layout.
  #let report(name) = g => [#metadata((name: name, w: g.width, a: g.baseline, d: g.height - g.baseline)) <compat-display>]
  $ nicemat(foreground: #report("display under setup"), 1, 2; 3, 4) quad
    nicemat(foreground: #report("display nested"), nicemat(1, 2; 3, 4), 0; 0, 1) $
  #context {
    let expected = (
      "display under setup": _ink(math.equation(math.display($mat(1, 2; 3, 4)$))),
      "display nested": _ink(math.equation(math.display($mat(mat(1, 2; 3, 4), 0; 0, 1)$))),
    )
    let found = query(<compat-display>).map(m => m.value)
    assert.eq(found.len(), 2)
    for f in found {
      let e = expected.at(f.name)
      let ok = calc.abs(e.w - f.w) < tol and calc.abs(e.a - f.a) < tol and calc.abs(e.d - f.d) < tol
      assert(ok, message: f.name + ": mat " + repr(e) + " vs nicemat " + repr(f))
      [#f.name ✓ \ ]
    }
  }
]

// With `mat: true`, every `mat` is drawn by `nicemat`, inline ones included.
#[
  #let before = state("before-inline")
  #context before.update(_ink(math.equation($mat(1, 2; 3, frac(4, 5))$)))
  #show: nicemat-setup.with(mat: true)
  #context {
    let after = _ink(math.equation($mat(1, 2; 3, frac(4, 5))$))
    let b = before.get()
    assert(calc.abs(b.w - after.w) < tol and calc.abs(b.a - after.a) < tol and calc.abs(b.d - after.d) < tol,
      message: "inline show rule: " + repr(b) + " vs " + repr(after))
    [inline show rule: $mat(1, 2; 3, frac(4, 5))$ ✓]
  }
]
