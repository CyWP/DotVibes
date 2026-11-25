# EB Garamond — vendored fonts

Full family (Regular, Italic, Bold, Bold-Italic) used by the DotVibes document
theme (`docs/marp-doc.css`, theme `dotvibes-doc`) for running text.

## Provenance

- Source: Google Fonts repo, `ofl/ebgaramond` (variable fonts, wght axis
  400–800):
  - `EBGaramond[wght].ttf`
  - `EBGaramond-Italic[wght].ttf`
- The four static weights here were instanced from those variable fonts with
  `fontTools.varLib.instancer.instantiateVariableFont(..., {"wght": 400|700},
  updateFontNames=True)` (fontTools 4.68, Nov 2026) — `fc-scan` reports family
  "EB Garamond" with Regular/Italic/Bold/Bold Italic styles and matching
  weight/slant bits.
- License: SIL Open Font License 1.1 (`OFL.txt`, kept alongside).

`garamond_[allfont.ru].ttf` is the pre-existing single-weight download (family
"Garamond"); it is not used by the theme, only installed alongside by
`fonts/install.sh`.
