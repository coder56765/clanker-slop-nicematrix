// Dotted leaders: examples from the nicematrix manual, in Typst syntax.
#import "/nicematrix.typ": *
#set page(width: 16cm, height: auto, margin: 1em)
#set text(size: 12pt)

#let ex(title, body) = block(breakable: false, below: 1.2em)[*#title* #h(1fr) #body]

#ex("basic", $ nicemat(delim: "[",
  a_1, dots.c, , , a_1;
  dots.v, a_2, dots.c, , a_2;
  , dots.v, ddots(fill: #red);
  ;
  a_1, a_2, , , a_n) $)

#ex("null matrix", $ nicemat(delim: "[", 0, dots.c, 0; dots.v, , dots.v; 0, dots.c, 0)
  quad nicemat(delim: "[", 0, dots.c, dots.c, 0; dots.v, , , dots.v; dots.v, , , dots.v; 0, dots.c, dots.c, 0)
  quad nicemat(delim: "[", 0, dots.c, , 0; dots.v, , , ; , , , dots.v; 0, , dots.c, 0) $)

#ex("wider", $ nicemat(delim: "[", 0, dots.c, #h(1cm), 0; dots.v, , , dots.v; 0, dots.c, , 0) $)

#ex("ldots vs nullify", $ C = nicemat(h, i, j, k, l, m; x, dots.h, dots.h, dots.h, dots.h, x)
  quad D = nicemat(dots: #(nullify: true), h, i, j, k, l, m; x, dots.h, , , , x) $)

#ex("hdotsfor", $ nicemat(1, 2, 3, 4, 5; 1, cdots(span: 3), 5; 1, 2, 3, 4, 5; 1, 2, 3, 4, 5)
  quad nicemat(1, 2, 3, 4, 5; , cdots(span: 3); 1, 2, 3, 4, 5; 1, 2, 3, 4, 5) $)

#ex("parallel diagonals", $ A = nicemat(1, dots.c, , 1; a+b, dots.down, , dots.v; dots.v, dots.down, , ; a+b, dots.c, a+b, 1)
  quad A = nicemat(1, dots.c, , 1; a+b, , , dots.v; dots.v, dots.down, dots.down, ; a+b, dots.c, a+b, 1)
  quad nicemat(dots: #(parallel: false), 1, dots.c, , 1; a+b, dots.down, , dots.v; dots.v, dots.down, , ; a+b, dots.c, a+b, 1) $)

#ex("labels", $ nicemat(delim: "[", 1, #h(1cm), 0; , ddots(above: n "times"), ; 0, , 1)
  quad nicemat(delim: "[", 1, #h(1cm), 0; , ddots(above: n "times", horizontal-labels: #true), ; 0, , 1) $)

#ex("tridiagonal, dashed", $ nicemat(dots: #(nullify: true, stroke: (dash: "loosely-dotted", thickness: 0.8pt)),
  a, b, 0, , dots.c, 0;
  b, a, b, dots.down, , dots.v;
  0, b, a, dots.down, , ;
  , dots.down, dots.down, dots.down, , 0;
  dots.v, , , , , b;
  0, dots.c, , 0, b, a) $)

#ex("iddots", $ nicemat(, , 1; , dots.up, ; 1, , ) quad nicemat(a, , , b; , , iddots(fill: #blue), ; , , , ; c, , , d) $)

#ex("resultant", $ nicemat(delim: "|", column-gap: #1.2em,
  a_0, , , , b_0, , ;
  a_1, dots.down, , , b_1, dots.down, ;
  dots.v, dots.down, , , dots.v, dots.down, b_0;
  a_p, , , a_0, , , b_1;
  , dots.down, , a_1, b_q, , dots.v;
  , , , dots.v, , dots.down, ;
  , , , a_p, , , b_q) $)

#ex("marks & middle label", $ nicemat(cdots(span: 3, middle: 3, marks: "<->", stroke: #0.4pt), , ; 1, 1, 1; 1, 1, 1) $)
