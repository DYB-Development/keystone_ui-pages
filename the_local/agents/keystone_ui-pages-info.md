---
name: keystone_ui-pages-info
description: Use to learn what Keystone UI Pages offers — the page builder, page layout, places, published versions, host values, sequences, PDFs, view and click reporting and the element catalog — and the vocabulary the install and develop locals assume.
tools: Read
scope: Pages — building, publishing and printing pages drawn with Keystone UI
---

This local explains Keystone UI Pages and sends you to the local that does the
work. It changes nothing and gives no steps.

## What Keystone UI Pages is

Keystone UI Pages is a Rails engine gem that adds a page builder to a host app.
A page is a JSON document of sections, rows, columns and elements, and every
element is drawn by a Keystone UI component, so a page looks like the rest of an
app built with Keystone UI. Editors change the draft in a builder in the
browser, and publishing it saves a numbered version. The live version is what
visitors, the host's own screens and PDFs show.

Reach for it when an app needs pages that people other than developers lay out
and change: marketing pages, client portal pages, funnels, report templates,
invoices. A page can hold values the host app supplies, such as a client's name,
so one page serves as a template drawn with each client's values, on screen or
as a PDF.

## Interface

This local declares no commands. The two working surfaces belong elsewhere:

- **Getting the gem into a host app** — adding it, running the engine's and
  Active Storage's migrations, mounting the engine, the layouts and the settings
  file → **`keystone_ui-pages-install`**.
- **Working with it** — every setting, places, who may view or edit, host
  values, sequences, drawing a page in the host's own screens, making PDFs,
  choosing how they are drawn, giving a host element a PDF drawing, view and
  click reporting, form answers, linking to the builder and changing the
  element catalog → **`keystone_ui-pages-develop`**.

## How to use it

One decision: is Keystone UI Pages already set up in the app?

- No, or the setup is out of date, such as a migration from a newer version not
  yet run → **`keystone_ui-pages-install`**.
- Yes, and there is a page to draw, a PDF to make, a place or sequence to add, a
  setting to change, an element to add or a PDF drawing to give one →
  **`keystone_ui-pages-develop`**.

Keystone UI itself must be installed first. Its own install local,
`keystone_ui-install`, does that.

## Conventions

- **Layout.** A page holds sections, a section holds rows, a row holds columns
  on a twelve-column grid, and a column holds elements. A section has a spacing
  of small, medium or large, can be shaded, and can be held to one of Keystone
  UI's page widths. A row has a gap between its columns. A column can be aligned
  to the top, centre or bottom, and an element to the start, centre or end of
  its column or stretched across it. Elements do not hold other elements.
- **Draft and versions.** A page's document is its draft. Publish copies the
  draft into a new numbered version marked live, and the previous live version
  is marked superseded. A page is a draft (never published), published,
  unpublished (has versions but none live) or archived (hidden from the list and
  unpublished). The builder's undo and redo history is kept with the page.
- **Owner and slug.** A page has a name, a slug that is its address, and an
  optional owner, which can be any record. When the host names an owner, every
  lookup is limited to the current owner's pages, and a slug is unique per
  owner.
- **Places.** Every page sits in a place the host defines, such as a marketing
  site or a client portal. A place sets the default name of new pages, which
  catalog elements its pages may use, whether it appears in the page list, and
  optional handlers for views and clicks, form answers, sequences and the next
  page.
- **Edit check, view check and access exceptions.** The host decides who may
  edit pages and who may view a published one, through methods on its own
  controller. An access exception is a named setting an editor puts on one page
  to let it past the view check, such as a public preview.
- **Host values.** Values the host names, such as a client's name or whether
  someone has purchased. An editor binds an element's field to one, with
  fallback text, or shows a section, row or element only when a value equals
  something. The host supplies the values each time it draws or prints a page.
- **Sequences.** Pages the host keeps in its own order, such as the steps of a
  funnel, built side by side in the builder. The host answers each sequence by
  its key, and the gem stores no order. A page made for a sequence keeps that
  sequence's key.
- **The catalog.** The list of Keystone UI components the builder offers as
  elements. A host adds elements drawn by its own components and leaves out
  ones it does not want.
- **Views and clicks.** The gem records nothing about visitors. A place with a
  handler is told of each view and click on the live page, and the browser fires
  matching events an analytics tag can listen for.
- **PDFs and the two drawings.** A PDF is made from a published version and a
  set of host values, and kept in Active Storage so the same request returns the
  same file. The Chrome drawing, the default, prints the page with Chrome or
  Chromium on the server from the host's stylesheet. The Ruby drawing needs no
  browser: it lays out the page's sections, rows, columns and elements as a
  screen as wide as the printed page would, and draws each element with Prawn.
- **PDF drawing.** Under the Ruby drawing each catalog element prints through
  its own PDF drawing, given when the element is registered. It draws with a
  fixed set of calls, such as text, boxes, rows and tables, each naming Keystone
  UI tokens like `--text-base` or `--ks-color-accent`, and prints in the values
  the host's stylesheet gives those tokens in light mode. A page holding an
  element with no PDF drawing cannot be printed that way. The bar chart and line
  chart have none yet, and the form, copy button and Next page elements print
  nothing.
- **A refused PDF.** A PDF that cannot be made is refused with a message saying
  why, such as a missing browser, an element with no PDF drawing, a character
  the font cannot draw, an unreadable token or a font with no TrueType copy. A
  refused PDF keeps no file, and a refusal while publishing does not stop the
  publish.
- Ruby >= 3.2 and Rails >= 7.1. It depends on keystone_ui >= 0.49.0,
  keystone_ui-styles >= 0.24.0, keystone_ui-react >= 0.1.3 and prawn ~> 2.5.
