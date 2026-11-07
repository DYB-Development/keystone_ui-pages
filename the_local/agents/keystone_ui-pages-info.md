---
name: keystone_ui-pages-info
description: Use to learn what Keystone UI Pages offers — the page builder, places, published versions, host values, sequences, PDFs, view and click reporting and the element catalog — and the vocabulary the install and develop locals assume.
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
- **Working with it** — what each setting does, places, who may view or edit,
  host values, sequences, drawing a page in the host's own screens, PDFs and
  which drawing makes them, view
  and click reporting, form answers, linking to the builder and changing the
  element catalog → **`keystone_ui-pages-develop`**.

## How to use it

One decision: is Keystone UI Pages already set up in the app?

- No, or the setup is out of date, such as a migration from a newer version not
  yet run → **`keystone_ui-pages-install`**.
- Yes, and there is a page to draw, a PDF to make, a place or sequence to add, a
  setting to change or an element to add → **`keystone_ui-pages-develop`**.

Keystone UI itself must be installed first. Its own install local,
`keystone_ui-install`, does that.

## Conventions

- **Draft and versions.** A page's document is its draft. Publish copies the
  draft into a new version marked live and marks the previous live version
  superseded. Only the live version is shown outside the builder. A page is in
  one of four states: draft (never published), published, unpublished (has
  versions but none live) or archived (hidden from the list and unpublished).
- **Pages belong to an owner.** A page has a name, a slug that is its address,
  and an optional owner, which is any record. When the host names an owner
  method, every lookup is limited to the current owner's pages, and a slug is
  unique per owner.
- **Places.** Every page sits in a place the host defines, such as a marketing
  site or a client portal. A place sets the default name of new pages, which
  catalog elements its pages may use, whether it appears in the page list, and
  optional handlers for views and clicks, form answers and sequences.
- **Who sees what.** The host decides who may edit pages and who may view a
  published one, each through a method on its own controller. An access
  exception is a named setting an editor puts on one page to let it past the
  view check, such as a public preview. A refused request gets the host's
  refusal, or a not found when the host names none.
- **Host values.** The host names the values a page can use, such as a client's
  name or whether someone has purchased. An editor binds an element's field to
  one, with fallback text for when it is blank, or shows a section, row or
  element only when a value equals something. The host supplies the values when
  it draws the page, and can offer sample visitors so the builder previews each
  version.
- **Sequences.** A host that keeps pages in its own order, such as the steps of
  a funnel, lets staff build them side by side. The host answers a sequence by
  its key with a title, its pages in order and a back address, or refuses it.
  It may also give the address of its own screen for the sequence, which the
  list links to as Flow. Each page in the list shows whether it is a
  draft, published or unpublished. The gem stores no order. Each page made for a sequence keeps that sequence's
  key, which cannot be changed later.
- **Adding a page to a sequence.** The sequence screen has an Add page button
  that asks for a name, with the place's default name used when it is left
  blank, and whether to start blank or as a copy of another page in the same
  place. The gem makes the page and tells the host which sequence it joins and
  which page was open, so the host decides where it goes in the order. The new
  page then opens in the builder beside the list. A place that answers
  sequences must also handle pages added this way.
- **The catalog.** The builder offers a fixed list of Keystone UI components as
  elements. A host adds elements drawn by its own components and leaves out ones
  it does not want. Navigation, form inputs, page frames and components whose
  data the catalog cannot describe are not offered. The one form element sends
  its answers to the place's form handler, and a place that offers it must have
  one.
- **Views and clicks.** The gem records nothing about visitors. A place with a
  handler is told of each view and each click on the live page, and the browser
  fires matching events a third-party analytics tag can listen for.
- **PDFs come from one of two drawings, chosen by the host.** The Chrome
  drawing, the default, prints the page with a Chromium-based browser on the
  server from the host's compiled stylesheet, so the PDF looks as the page does.
  The Ruby drawing needs no browser and draws the page's sections, rows, columns
  and elements with Prawn, in Prawn's default font. In the Ruby drawing each
  element draws through its own PDF drawing, given when the element is added to
  the catalog. A page holding an element with no PDF drawing cannot be printed
  that way, and the error names the element. So far only the heading and label
  elements have one.
- **PDFs are kept in Active Storage**, one per published version and set of
  values, whichever drawing made them. A page that uses no host values gets its
  PDF made when it is published.
- **The editor's screens.** The page list, the builder, the sequence screen, the
  version history and View live are open to whoever passes the host's edit
  check. The builder's undo and redo history is kept with the page.
- Ruby >= 3.2. Rails >= 7.1. It depends on keystone_ui >= 0.49.0,
  keystone_ui-styles >= 0.24.0, keystone_ui-react >= 0.1.3 and prawn ~> 2.5.
