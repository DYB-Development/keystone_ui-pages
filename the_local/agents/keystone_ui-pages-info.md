---
name: keystone_ui-pages-info
description: Use to learn what Keystone UI Pages offers — the page builder, published versions, host values, PDFs and the element catalog — and the vocabulary the install and develop locals assume.
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
and change: marketing pages, report templates, invoices. A page can hold values
the host app supplies, such as a client's name, so one page serves as a template
drawn with each client's values, on screen or as a PDF.

## Interface

This local declares no commands. The two working surfaces belong elsewhere:

- **Getting the gem into a host app** — adding it, running the engine's and
  Active Storage's migrations, mounting the engine, the layouts and the settings
  file → **`keystone_ui-pages-install`**.
- **Working with it** — what each setting does, host values, drawing a page in
  the host's own screens, PDFs, linking to the builder and changing the element
  catalog → **`keystone_ui-pages-develop`**.

## How to use it

One decision: is Keystone UI Pages already set up in the app?

- No, or the setup is out of date → **`keystone_ui-pages-install`**.
- Yes, and there is a page to draw, a PDF to make, a setting to change or an
  element to add → **`keystone_ui-pages-develop`**.

Keystone UI itself must be installed first. Its own install local,
`keystone_ui-install`, does that.

## Conventions

- **Draft and versions.** A page's document is its draft. Publish copies the
  draft into a new version marked live and marks the previous live version
  superseded. Only the live version is ever shown outside the builder. A page
  with no live version shows nothing.
- **Pages belong to an owner.** A page has a name, a slug that is its address,
  and an optional owner, which is any record. When the host names an owner
  method, every lookup is limited to the current owner's pages, and a slug is
  unique per owner.
- **Host values.** The host names the values a page can use, such as a client's
  name or a score. An editor binds an element's field to one, with fallback text
  for when it is blank, or shows a section, row or element only when a value
  equals something. The host supplies the values when it draws the page.
- **The catalog.** The builder offers a fixed list of Keystone UI components as
  elements. A host adds elements drawn by its own components and leaves out ones
  it does not want. Navigation, form inputs, page frames and components whose
  data the catalog cannot describe are not offered.
- **PDFs are printed by Chrome or Chromium on the server** and kept in Active
  Storage, one per live version and set of values.
- **The editor's screens.** The page list, the builder, the version history and
  View live all sit under the engine's `manage` routes and are open to whoever
  passes the host's edit check.
- Ruby >= 3.2. Rails >= 7.1. It depends on keystone_ui >= 0.49.0,
  keystone_ui-styles >= 0.24.0 and keystone_ui-react >= 0.1.3.
