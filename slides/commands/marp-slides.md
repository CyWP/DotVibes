---
description: Turn notes, documents, reports or an outline into plain slide markdown and build it to PDF/HTML with `marp-build`, which adds the theme, cover, footer and author itself (logo and background are optional build arguments). Usage: /marp-slides <source file or topic> [pdf|html]
---

# marp-slides

Source: $ARGUMENTS (a file path, or notes in the conversation).

Your job is **content**: turn the source into well-structured slide markdown.
Everything about look and branding (theme, front matter, cover slide, footer,
author name, page number, colours, light/dark) is done automatically by
`marp-build`; logo and background are optional build arguments. Don't write any of it into the deck.

## Workflow

1. Read the source (notes, doc, report). Decide audience and rough length
   (default: ~1 slide per minute; ask only if the purpose is truly unclear).
2. Write `<name>.md` next to the source (or where the user says; never
   overwrite the source): plain markdown following the rules below, no front
   matter needed.
3. Build ONLY with `marp-build` — never call `marp` or `npx @marp-team/marp-cli`
   directly, and never pass CSS/theme flags other than those below:
   - `marp-build <name>.md` -> PDF (default); `-t html` -> HTML.
   - `-T dark` for a dark deck (default light); honor a light/dark choice from
     the arguments.
   - `--bundle` -> portable HTML folder `<name>/` (`index.html` + `assets/`
     with fonts, images, videos) for a USB key / another computer. PDFs are
     already self-contained, so don't bundle those.
   - Logo and background are OPTIONAL ARGUMENTS, only when the user gives
     them (there are no defaults, and never write them into the deck):
     `--logo FILE`, `--logo-corner tr|tl|bl|br[,wm]` (default `tr`; `wm` =
     faded watermark), `--background FILE`. A logo never appears on the cover.
     Open a background image first: if it is busy or dark behind dark text,
     say so and suggest a lighter one; never fix it by recolouring text.
   - `--author NAME|none` only if the user wants a different author (default:
     their git name).
   - Report the output path. If `marp-build` fails because marp or Chrome is
     missing, say so rather than installing anything.

## What marp-build adds (do NOT write these yourself)

Front matter (`marp`, `theme`, `paginate`), the footer (author + deck title,
every slide but the cover), the cover treatment, the author byline,
page numbers and the coloured squares. The deck title is taken from the first
`# ` heading, so make slide 1 exactly:

```markdown
# Deck title

## Subtitle (topic, or date)
```

(A first slide with a `# ` heading becomes the cover automatically; use `# `
only there, `## ` for every other slide title.)

## Structure

- Slide breaks: a line containing only `---`, with a blank line above AND
  below. Without the blank line above, `---` turns the preceding text into
  an H2 instead of splitting. Headings never split slides; write an explicit
  `---` before every new slide.
- Titles: short, at most ~32 characters so they stay on one line beside the
  logo; abbreviate to the key phrase when the source heading is longer
  ("Reliability: training configuration checks" -> "Reliability: config checks").
  The theme never rescales titles or the footer.
- One idea per slide; a `## Heading` stating the point, then 3-5 bullets of
  at most ~10 words, or one table / code block / image. Split rather than shrink.
- Per-slide classes go in a comment inside that slide: `<!-- _class: small -->`
  for denser content (shrinks only the body), `<!-- _class: lead -->` for a
  section-break slide. Keep the underscore (`_class`): without it the class
  sticks to every later slide too. Never `invert` per slide to get a dark
  deck: use `-T dark`.
- Two columns: `<div class="cols"><div>` … `</div><div>` … `</div></div>`
  with blank lines inside so markdown renders. Use `### What` / `### Results`
  style small labels at the top of each column when the source has them.
- A slide whose only content is one table, or one image paragraph, is centred
  automatically (below the title): don't add spacing hacks. Put nothing else
  on such a slide, or the auto-centring switches off.
- Speaker notes / detail not for the slide: HTML comments `<!-- … -->`.
- End with a summary / next steps slide when the source has conclusions.

## Tables, images and media

- Screenshots in the source: before treating an image as an image, open it
  (Read) and check whether it is really information — a table, list, config,
  code, terminal output, a simple chart's numbers. If so, transcribe it into
  native slide content (markdown table, bullets, code block) so it is crisp,
  themed and editable; keep the image only when it is genuinely visual
  (plots, diagrams, photos, UI layouts) or can't be transcribed faithfully.
  Copy figures exactly; mark anything illegible with a `<!-- TODO -->`
  comment and flag it to the user rather than guessing.
- CSV files (linked or referenced in the source): don't transcribe them by
  hand; put a directive on its own line and `marp-build` expands it into a
  markdown table at build time (all output formats):
  `<!-- csv: data/results.csv max=8 cols=8 -->` (path relative to the deck;
  options `max` data rows, `cols` columns, `sep` delimiter; `max=all` /
  `cols=all` lift a limit). Numbers are right-aligned, values copied exactly.
  Pick `max`/`cols` so the table fits the slide without shrinking the font
  (~8 rows x 6-8 short columns; add `<!-- _class: small -->` for up to ~12
  rows). Bigger files are cut with a `…` row and an "N of M rows" note under
  the table; choose the rows that matter or say so, and keep a link to the
  file. A missing/empty CSV fails the build: fix the path, don't paste data.
  Only for real CSV files; tables in screenshots still need transcribing.
- Images: `![w:600](path.png)`; `![center h:430](path.png)` centres a lone image
  (max ~h:430 under a one-line title); spaces in file names as `%20`;
  `![bg right:40%](path.png)` for side images. Paths relative to the .md file.
- Links stay clickable in both PDF and HTML.
- GIFs: `![h:300](clip.gif)` like any image; animates in HTML, a PDF shows the
  first frame only (mention it if the motion matters).
- Video files (`.mp4`, `.webm`, ...): `<video src="clip.mp4" controls width="560"></video>`,
  optionally `poster="frame.png"`. Never `![](clip.mp4)` (renders broken).
  HTML plays it; for PDF `marp-build` swaps the tag itself for the poster (or
  an ffmpeg first frame, else a "▶ clip.mp4" link) pointing at the file's
  local path, so for sharing use `--bundle`. Keep the `<video>` tag either way.
- YouTube: a PDF cannot play it and an `<iframe>` renders there as a dead box,
  so for PDF (default) use a thumbnail that links to the video:
  `[![w:420](https://img.youtube.com/vi/<ID>/hqdefault.jpg)](https://www.youtube.com/watch?v=<ID>)`
  (needs network at build time). Only for `-t html` output use
  `<iframe src="https://www.youtube.com/embed/<ID>" width="560" height="315"></iframe>`.
  Say which you used.

## Converting source material

- Compress prose, don't transcribe it (screenshots of data are the
  exception): headings -> slide titles, key claims -> bullets, numbers ->
  tables, long prose -> notes comments.
- Keep facts, figures and wording of conclusions faithful; never invent
  content. Flag gaps (e.g. missing figure) to the user instead of filling them.
- Preserve code only if it's the point; trim to the relevant lines.
