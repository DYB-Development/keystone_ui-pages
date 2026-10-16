# Changelog

All notable changes to this project will be documented in this file.

## [Unreleased]

### Fixed
- A host app that loads Action View while it starts, such as one with an initializer that names `ActionView::Base`, now boots with the engine installed.

## [0.1.0] - 2026-10-16

### Added
- A drag-and-drop page builder whose pages are drawn with keystone_ui components, laid out in sections, rows and columns that move, duplicate and remove from a toolbar or the keyboard.
- An element catalog of keystone_ui components, including headings, label and value lists, tables with groups, subtotals and a total row, bar and line charts, and stats with a note, a plain style and a fallback, which a host app can add to or leave elements out of.
- Text settings that take a value the host app supplies when a page is drawn, sample values to preview them in the builder, and show-when conditions that hide a section, row or element unless a value matches.
- Phone, tablet, desktop and print widths in the builder, and Mode and Look choices that follow the host app's keystone themes.
- Published versions at `/pages/:slug`, a history of versions that can be restored, and `keystone_ui_page(page, values:)` to draw a published page inside the host app's own screens.
- Print styles and PDFs printed by Chrome or Chromium on the server, kept with Active Storage, made at publish for a page that uses no host values and on request with `KeystoneUi::Pages.pdf` or ahead of time with `prepare_pdf`.
- A list of every page with links to edit it, view it live with the chosen sample values and download its PDF.
- A Back link in the builder that returns to the address a host app names with `return_to`.
- Undo and Redo in the builder, kept with the page so they survive a reload and a publish.
- the_local notes that teach a host app's coding agents to install and use pages.
