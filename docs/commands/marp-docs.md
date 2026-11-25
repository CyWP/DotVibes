---
description: Turn notes, documents, data or an outline into a paged document (report, essay, memo — meant to be read page by page) as plain Marp markdown and build it to PDF/HTML with `marp-doc-build`, which adds the theme, title page, footer and author itself (contents page, logo and background are optional build arguments). Usage: /marp-docs <source file or topic> [pdf|html]
---

# marp-docs

Source: $ARGUMENTS (a file path, or notes in the conversation).

Your job is **content**: turn the source into well-structured document markdown.
Everything about look and branding (theme, page size, front matter, title page,
footer, author name, page numbers, colours) is done automatically by
`marp-doc-build`; contents page, logo and background are optional build
arguments. Don't write any of it into the document.

## Workflow

1. Read the source (notes, doc, data). Decide the form: **report** (titled
   sections, tables/figures, conclusions — default for mixed or factual
   material) or **prose** (an essay: continuous paragraphs, minimal headings).
   Decide audience and rough length (default: ~300 words per page; ask only if
   the purpose is truly unclear).
2. Write `<name>.md` next to the source (or where the user says; never
   overwrite the source): plain markdown following the rules below, no front
   matter needed.
3. Build ONLY with `marp-doc-build` — never call `marp`, `npx @marp-team/marp-cli`
   or plain `marp-build` directly, and never pass CSS/theme flags other than
   those below:
   - `marp-doc-build <name>.md` -> PDF (default); `-t html` -> HTML.
   - `--paper a4` for A4 (default US Letter); honor a paper-size choice from
     the arguments.
   - `--toc` -> an automatic contents page with page numbers (report mode:
     suggest it when there are more than ~4 sections). Front matter `toc: true`
     in the source does the same.
   - `--bundle` -> portable HTML folder `<name>/` (`index.html` + `assets/`
     with fonts, images) for a USB key / another computer. PDFs are already
     self-contained, so don't bundle those.
   - Logo and background are OPTIONAL ARGUMENTS, only when the user gives them
     (there are no defaults, and never write them into the deck):
     `--logo FILE`, `--logo-corner tr|tl|bl|br[,wm]` (default `tr`; `wm` =
     faded watermark), `--background FILE`. For documents the logo is a cover
     watermark: it appears on the title page only. Open a
     background image first: if it is busy or dark behind dark
     text, say so and suggest a lighter one; never fix it by recolouring text.
   - `--author NAME|none` only if the user wants a different author (default:
     their git name). `--date DD/MM/YY|none` only if the user wants a date
     other than today (default: today's date).
   - `--team NAME|none` puts a TEAM name in the running footer instead of the
     author's (a document a team worked on is the team's, not one person's).
     Ask whether the document should carry a team name when you start; if so,
     pass it here (the cover byline still shows the author).
   - Report the output path. If the build fails because marp or Chrome is
     missing, say so rather than installing anything.

## What marp-doc-build adds (do NOT write these yourself)

Front matter (`marp`, `theme`, `paginate`, `size`), the footer (name — author
or team —, date, doc title, every page but the title page), the title-page
treatment, the
author + date byline, page numbers and the palette hairline. The doc title is
taken from the first `# ` heading, so make page 1 exactly:

```markdown
# Document title

## Subtitle (the topic; the date is added automatically)
```

(A first page with a `# ` heading becomes the title page automatically; use
`# ` only there, `## ` for section headings, `### ` for sub-headings inside a
section. `## ` headings are what `--toc` lists, so write them as section
titles, not as topic labels.)

## Pages and flow

- Pages are US Letter portrait; nothing flows automatically — content that
  doesn't fit a page is CLIPPED silently. You own the page breaks: write an
  explicit `---` (line containing only `---`, blank line above AND below)
  wherever a new page starts. Without the blank line above, `---` turns the
  preceding text into an H2 instead of splitting.
- A full page of running text is roughly 30-33 lines (~300-330 words). Budget
  headings (~3 lines), list items, table rows (~25 rows max per page), code
  lines (~30 max) and images the same way. When in doubt, break earlier.
- Report mode: start each `## ` section on a fresh page (unless a section is
  very short — then keep two short sections together on one page rather than
  scattering half-empty pages). Prose mode: run paragraphs continuously and
  break only when the page is full.
- NEVER let a page overflow: split a section across pages at a paragraph
  boundary, or use `<!-- _class: small -->` for a dense table/code page
  (shrinks only the body). Never shrink with HTML or inline styles.
- Speaker notes / detail not for the document: HTML comments `<!-- … -->`.
- End with a conclusions / next steps section when the source has them (report
  mode); an essay just ends with its strongest paragraph.
- Per-page classes go in a comment inside that page: `<!-- _class: small -->`
  for denser content. Two columns: `<div class="cols"><div>` … `</div><div>`
  … `</div></div>` with blank lines inside so markdown renders — for
  side-by-side comparisons, not for squeezing more prose onto a page.

## Prose style (this is NOT a slide deck)

- Write each paragraph and each list item as a SINGLE line — never hard-wrap
  your source. Marp renders a single newline inside a paragraph as a forced
  line break, so wrapped source breaks sentences mid-flow wherever the wrap
  happens to fall. Blank lines still separate paragraphs.

- Documents are read, not presented: write real sentences and paragraphs;
  keep the source's reasoning, wording of conclusions, and flow. Compress only
  obvious padding — don't shred prose into bullets (slides do that; this
  doesn't). Bullets are for genuine enumerations.
- Keep facts, figures and claims faithful; never invent content. Flag gaps
  (e.g. missing figure) to the user instead of filling them.
- Preserve code only if it's the point; trim to the relevant lines.

## Tables, images and media

- Screenshots in the source: before treating an image as an image, open it
  (Read) and check whether it is really information — a table, list, config,
  code, terminal output, a simple chart's numbers. If so, transcribe it into
  native document content (markdown table, paragraphs, code block) so it is
  crisp, themed and editable; keep the image only when it is genuinely visual
  (plots, diagrams, photos, UI layouts) or can't be transcribed faithfully.
  Copy figures exactly; mark anything illegible with a `<!-- TODO -->` comment
  and flag it to the user rather than guessing.
- CSV files (linked or referenced in the source): don't transcribe them by
  hand; put a directive on its own line and `marp-doc-build` expands it into a
  markdown table at build time (all output formats):
  `<!-- csv: data/results.csv max=18 cols=8 -->` (path relative to the doc;
  options `max` data rows, `cols` columns, `sep` delimiter; `max=all` /
  `cols=all` lift a limit). Numbers are right-aligned, values copied exactly.
  A page fits ~18 rows x 6-8 short columns (~12 with
  `<!-- _class: small -->`). Bigger files are cut with a `…` row and an
  "N of M rows" note under the table; choose the rows that matter or say so,
  and keep a link to the file. A missing/empty CSV fails the build: fix the
  path, don't paste data. Only for real CSV files; tables in screenshots still
  need transcribing.
- Images: `![w:480](path.png)` inline in a paragraph; `![center h:600](path.png)`
  centres a lone image (max ~h:600 under a one-line heading); spaces in file
  names as `%20`. Paths relative to the .md file. A page whose only content is
  one image paragraph, or one table, is centred automatically — put nothing
  else on such a page.
- Links stay clickable in both PDF and HTML.
- GIFs: `![h:300](clip.gif)` like any image; animates in HTML, a PDF shows the
  first frame only (mention it if the motion matters).
- Video files (`.mp4`, `.webm`, ...): `<video src="clip.mp4" controls width="480"></video>`,
  optionally `poster="frame.png"`. Never `![](clip.mp4)` (renders broken).
  HTML plays it; for PDF `marp-doc-build` swaps the tag itself for the poster
  (or an ffmpeg first frame, else a "▶ clip.mp4" link) pointing at the file's
  local path, so for sharing use `--bundle`. Keep the `<video>` tag either way.
- YouTube: a PDF cannot play it and an `<iframe>` renders there as a dead box,
  so for PDF (default) use a thumbnail that links to the video:
  `[![w:420](https://img.youtube.com/vi/<ID>/hqdefault.jpg)](https://www.youtube.com/watch?v=<ID>)`
  (needs network at build time). Only for `-t html` output use
  `<iframe src="https://www.youtube.com/embed/<ID>" width="480" height="270"></iframe>`.
  Say which you used.
