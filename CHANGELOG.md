# Changelog

All notable changes to this project will be documented in this file.

## [Unreleased]

## [0.7.0] - 2026-10-21

### Added
- The New page form takes a `place` in its link, creates the page in that place, and then asks for a name only.
- A page created with no name is named with its place's word from `KeystoneUi::Pages.default_names` and the next number in that place, such as "Report template 3", or "Page 3" when the place has no word.
- A page created with no slug gets a random one.
- The page list takes a `place` in its link and shows only that place's pages, and its Create and archived links keep the place.

### Changed
- Creating a page with a place the host does not name shows the New page form again instead of raising.
- The builder's Back link and the redirects after saving settings, archiving and restoring go to the page's place list when the page has a place.

## [0.6.0] - 2026-10-21

### Added
- `KeystoneUi::Pages.pdf(page, version:)` and `prepare_pdf(page, version:)` print the published version with that number, live or superseded, so a record made from an older version prints the way it draws.

## [0.5.0] - 2026-10-21

### Added
- `keystone_ui_page(page, version:)` draws the published version with that number, live or superseded, so a record made from an older version keeps drawing the way it did.

## [0.4.1] - 2026-10-20

### Fixed
- A page holding an element the catalog no longer offers draws its other elements instead of failing, marks the missing one in the editor, and reports the page through Rails' error reporter.

## [0.4.0] - 2026-10-20

### Added
- An editor gives a page a title for the browser tab, which reaches visitors when the page is published, and a host reads it from the live version.
- An editor writes a paragraph as rich text and links selected words, and visitors see only its paragraphs, line breaks and links with safe addresses, with links to other sites opening in a new tab.
- An editor types each feature's icon in a feature grid, such as an emoji, and a typed icon is drawn as text so a script in it never runs.
- An editor sets a section's background to shaded, filling the page's width in keystone_ui's muted fill colour, and its width to one of keystone_ui's page widths, with padding from keystone_ui's spacing value.

## [0.3.0] - 2026-10-19

### Added
- An editor changes a page's name, slug and place on the page's settings page, opened from the page list, and a slug another page of the same owner already uses is refused with a message.

## [0.2.0] - 2026-10-19

### Fixed
- The page list offers Create, so an editor can make a page without knowing the New page form's address.

### Added
- A page records the place it belongs to, from the places a host app names with `KeystoneUi::Pages.places`, chosen when the page is created.
- An editor sets or clears a page's access exception in the builder, from the exceptions a host app names with `KeystoneUi::Pages.access_exceptions`.
- The host app's view check reads a page's place and access exception, and the page list shows both.
- An editor unpublishes a page from the builder, and archives or restores a page from the page list, which shows each page as Draft, Published, Unpublished or Archived.
- A published page at the engine's own address is drawn with the values a host app gives for the current visitor, through the controller method it names with `KeystoneUi::Pages.values_method`, so show-when conditions and bound text work there.

## [0.1.1] - 2026-10-16

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
