// `nicemat` must reproduce the geometry of `mat` (in a display equation)
// for plain matrices.
#import "/src/lib.typ": *
#import "/src/metrics.typ": ink

#set page(width: auto, height: auto, margin: 1em)

#let tol = 0.05pt
#let check(name, a, b) = context {
  let (ma, mb) = (ink(math.equation(math.display(a))), ink(math.equation(b)))
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
#context before.update(ink(math.equation(math.display(plain))))
#[
  #show math.mat: nicemat
  #context {
    let after = ink(math.equation(math.display(plain)))
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
