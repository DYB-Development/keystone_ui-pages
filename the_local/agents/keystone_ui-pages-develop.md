---
name: keystone_ui-pages-develop
description: Use PROACTIVELY for working with Keystone UI Pages in a host app — its settings, host values, drawing a page in the host's own screens, making PDFs, linking editors to the builder, and adding or leaving out catalog elements — MUST BE USED instead of hand-building page drawing or PDF printing.
tools: Read, Write, Edit, Grep
scope: Pages — building, publishing and printing pages drawn with Keystone UI
---

This local works with Keystone UI Pages from the host app's side. It always
works the same way: set what the engine asks the host for, hand it values, and
draw or print the live version through the gem's own calls rather than reading
page documents directly.

## What Keystone UI Pages is

Keystone UI Pages is a Rails engine that adds a page builder to a host app. A
page is a JSON document of sections, rows, columns and elements, each element
drawn by a Keystone UI component. Editors change a page's draft in the builder,
and Publish saves it as a numbered live version. The host draws the live
version in its own screens, prints it to PDF, and supplies values such as a
client's name that bound fields and conditions read.

Fire on any request to draw a page in a host screen, make or send a page as a
PDF, give editors a link to the builder, supply values to pages, add a
host-drawn element or remove one from the builder, or change who may view or
edit pages. If the engine is not mounted or its migrations have not run, that
is the `keystone_ui-pages-install` local's job, not this one's.

## Interface

All settings are plain writers, set in `config/initializers/keystone_ui_pages.rb`.
Every method a setting names is called on the engine's controllers, which
inherit from the base controller, so define it there.

### Access and layout settings

- `KeystoneUi::Pages.base_controller = "ApplicationController"` — a string
  naming the class every engine controller inherits from. Defaults to
  `"ActionController::Base"`. Its filters run on every engine request,
  including published pages.
- `KeystoneUi::Pages.owner_method = :current_team` — a method with no
  arguments returning the record that owns pages, such as a team or account.
  Every lookup, in the editor's screens and on published pages, is then limited
  to `KeystoneUi::Pages::Page.where(owner: <that record>)`, and a new page is
  created with it as owner. Unset, every page is visible to everyone and new
  pages have no owner.
- `KeystoneUi::Pages.view_check_method = :may_view_page?` — a method taking the
  page and returning true when the current visitor may see the published page
  at `/pages/:slug`. Unset, every published page is shown.
- `KeystoneUi::Pages.places = { "marketing" => "Marketing site" }` — a hash of
  the places a page can belong to, each stored value to the label editors see.
  When it is not empty, the New page form offers them with no blank choice, a
  page with no place or a place not in it is refused, and the page list shows each page's place. The view check
  reads it as `page.place`. Unset, pages have no place.
- `KeystoneUi::Pages.register_place("client_report", label: "Client report", default_name: "Report template", slug: false)`
  — adds one place with its own settings, so each part of a host app registers
  the place it uses and two registrations never replace each other. `label:` is
  what editors see. `default_name:` is the word a page created with no name
  starts with, followed by the next number among that owner's pages in that
  place, so "Report template 1", then "Report template 2"; it defaults to
  "Page". `slug:` says whether the place's pages have a URL slug; it defaults to
  true. A page in a place registered with `slug: false` is never served at
  `/pages/:slug`, whatever the view check says. Registered places are offered alongside any set with `places =`, and
  `places = nil` clears both.
- `KeystoneUi::Pages.access_exceptions = { "public_preview" => "Public preview" }`
  — a hash of the exceptions an editor can set on a page, each stored value to
  its label. When it is not empty, the builder's top bar has an Access exception
  choice that sets or clears one, an exception not in it is refused, and the page
  list shows each page's exception. The view check reads it as
  `page.access_exception`. Unset, the choice is not shown.
- `KeystoneUi::Pages.values_method = :page_values` — a method taking the page
  and returning a hash of value names to values for the current visitor. The
  engine calls it each time it draws a published page at `/pages/:slug`, so
  bound fields and show-when conditions follow the visitor there. The drawing is
  cached per version and per set of values, so no visitor gets a copy drawn for
  other values. Unset, published pages draw with no values.
- `KeystoneUi::Pages.edit_check_method = :may_edit_pages?` — a method with no
  arguments returning true when the current user may use the editor's screens:
  the page list, the builder, View live, History and the PDF link. It runs
  before every one of those requests. Unset, everyone may.
- `KeystoneUi::Pages.refusal_method = :refuse_page` — a method with no
  arguments that renders the response when a request is refused: a failed view
  or edit check, an unknown slug, or a page with no live version, which covers a
  draft, an unpublished page and an archived page. Unset, the response is an
  empty 404.
- `KeystoneUi::Pages.layout = "application"` — the host layout published pages
  and View live are drawn in. Defaults to `"application"`.
- `KeystoneUi::Pages.editor_layout = "editor"` — the host layout the page
  list, the builder and the version history are drawn in. Defaults to
  `"application"`.

### PDF settings

- `KeystoneUi::Pages.chrome_path = "/usr/bin/chromium"` — the Chrome or
  Chromium program that prints PDFs. Unset, the gem uses the `CHROME_BIN`
  environment variable, then the first of `/usr/bin/google-chrome`,
  `/usr/bin/google-chrome-stable`, `/usr/bin/chromium`,
  `/usr/bin/chromium-browser`, and the Google Chrome and Chromium apps in
  `/Applications` that can be run.
- `KeystoneUi::Pages.pdf_stylesheet = "tailwind.css"` — the name of the host's
  compiled stylesheet in Propshaft, written into every PDF. Defaults to
  `"tailwind.css"`. A name Propshaft cannot find prints the PDF with no styles.

### Host values

- `KeystoneUi::Pages::Values.names = { "client_name" => "Client name" }` — a
  hash of the value names the host supplies, each to the label the builder
  shows. When it is not empty, an editor can bind a text, long text, address,
  number, list or data field to one, with fallback text drawn when the value is
  blank, and can show a section, row or element only when a value equals some
  text.
- `KeystoneUi::Pages::Values.chooser = ->(page) { [["Acme report", "acme"]] }`
  — a callable taking the page and returning `[label, choice]` pairs. The
  builder shows them in a "Preview with" choice, opening on the first pair, and
  remembers the editor's choice per page for the session. Unset, the choice is
  not shown.
- `KeystoneUi::Pages::Values.provider = ->(page, choice) { { "client_name" => "Acme" } }`
  — a callable taking the page and a choice from the chooser and returning a
  hash of value names to values. The builder's canvas, View live and the page
  list's PDF link draw the page with what it returns for the chosen choice.
  Unset, they draw with no values.

### Drawing and printing

- `keystone_ui_page(page, values: {}, version: nil)` — a view helper, available
  in every host view, that draws the page's live version with the values given,
  inside a `<div class="@container">`. It returns nil when no version is live.
  `values:` takes value names to values, with string or symbol keys.
  `version:` takes a published version's number and draws that version
  instead, whether it is live or superseded and whether the page is
  unpublished or archived. It returns nil when the page has no version with
  that number. A record made from a page keeps the number it was made with
  and passes it here, so it keeps drawing the same way after later publishes.
- `KeystoneUi::Pages.pdf(page, values: {}, version: nil)` — returns a
  `KeystoneUi::Pages::Pdf` record for the page's live version drawn with the
  values given. Its `file` is an Active Storage attachment, ready to download,
  link or email. The same version and values return the record already
  kept, and a newly published version or different values print a new one.
  When nothing is kept it prints in the current request. `version:` takes a
  published version's number and prints that version instead, live or
  superseded, the same way `keystone_ui_page` draws it.
- `KeystoneUi::Pages.prepare_pdf(page, values: {}, version: nil)` — queues
  `KeystoneUi::Pages::PdfJob`, which calls `KeystoneUi::Pages.pdf` with the same
  page, values and version, so the file is kept before anyone asks for it.

### The builder and the editor's screens

- `/manage/pages` under the engine's mount path — the editor's page list, which
  at the `/pages` mount is `/pages/manage/pages`, or
  `keystone_ui_pages.manage_pages_path` from the host.
- `/pages/manage/pages/:id?return_to=/admin/marketing` — the builder for one
  page, or `keystone_ui_pages.manage_page_path(page, return_to: "/admin/marketing")`.
  `return_to` must be a path on the host's own site, starting with a single
  `/`. The builder's Back link returns there, even after Publish reloads the
  builder. With no `return_to`, or one pointing at another site, Back goes to
  the page list.

### The element catalog

- `KeystoneUi::Pages.catalog.register(key:, name:, component:, fields:, body: nil, icon: nil, group: nil, align: nil)`
  — adds an element to the builder's palette, or replaces the one with the same
  key. `key:` is a symbol stored in page documents. `name:` is the label in the
  palette. `component:` is the name of a method the drawing calls with one
  keyword argument per field, such as a `helper_method` on the base controller.
  `body:` names one field whose value is passed as the method's block instead
  of a keyword. `icon:` is one of `:cursor` `:tag` `:copy` `:heading` `:text`
  `:list` `:info` `:code` `:alert` `:card` `:megaphone` `:chart` `:bars`
  `:number` `:progress`, and any other value shows a box. `group:` is the
  palette heading it sits under, `"Other"` when unset. `align:` is the default
  placement in its column: `"stretch"`, `"start"`, `"center"` or `"end"`.
- `KeystoneUi::Pages.catalog.leave_out(:copy_button)` — removes elements from
  the palette by key. Takes several keys.

Each entry in `fields:` is a hash. Its `key:` is the keyword the component
receives and its `label:` is the label in the builder's field panel. Its
`kind:` is one of `:text` (the default when no kind is given), `:long_text`,
`:address`, `:number`, `:one_of`, `:yes_or_no`, `:list` or `:data`. A number
arrives as an Integer, or a Float when it has a decimal point, a `:one_of`
arrives as a symbol, and a `:yes_or_no` as true or false. Its `default:` is the
value used until the editor sets one. A `:one_of` field takes `options:`, the
list of choices as strings. A `:list` field takes `entry:`, an array of field
hashes describing each entry's parts, and each entry arrives as a hash with
symbol keys.

A `:data` field cannot be typed in the builder. It holds data the host
supplies through a bound value.

The catalog offers these Keystone UI components by default: `button`,
`progress`, `alert`, `code`, `heading`, `label`, `paragraph`, `hero`,
`cta_banner`, `card`, `stat_card`, `figure`, `info`, `badge`, `copy_button`,
`feature_grid`, `accordion`, `data_table`, `bar_chart`, `line_chart` and
`value_list`.

## How to use it

1. Confirm the engine is mounted and its migrations have run: `config/routes.rb`
   mounts `KeystoneUi::Pages::Engine` and `db/schema.rb` has
   `keystone_ui_pages_pages`. If not, stop and hand off to
   `keystone_ui-pages-install`.

2. Read `config/initializers/keystone_ui_pages.rb` before changing a setting.
   Every setting from the Interface is set there, and the methods they name are
   on the controller named by `base_controller`.

3. To change who may see or edit pages, set `owner_method`,
   `view_check_method`, `edit_check_method` or `refusal_method`, and write the
   method on the base controller. Who may see and change what is the
   developer's decision. Ask before choosing a rule.

4. To let pages use the host's data, set `Values.names` to the values the host
   can supply. To let editors preview a page with real data, also set
   `Values.chooser` and `Values.provider`. Ask the developer which records the
   chooser lists, since it decides what editors see in the builder.

5. To draw a page in a host screen with one client's values, find the page and
   call the helper:

   ```erb
   <% page = KeystoneUi::Pages::Page.find_by(slug: "report", owner: current_team) %>
   <%= keystone_ui_page(page, values: { "client_name" => @client.name, "score" => @client.score }) %>
   ```

   The drawing is kept in `Rails.cache` under the version and the values, so
   the same version and values are drawn once. A page that uses host values
   should be drawn this way unless the host sets `values_method`, since without
   it the published address `/pages/:slug` draws with no values: bound fields
   show their fallback text there, and conditions on a value hide what they
   guard unless they compare against blank.

6. To make a PDF:

   ```ruby
   pdf = KeystoneUi::Pages.pdf(page, values: { "client_name" => "Acme" })
   pdf.file
   ```

   To have it ready before anyone downloads it, such as when an invoice is
   created, call `KeystoneUi::Pages.prepare_pdf(page, values: ...)` instead and
   read `KeystoneUi::Pages.pdf` later with the same values. Publishing a page
   that uses no host values queues its PDF straight away, since it looks the
   same for everyone.

   The page must be published, since only the live version is printed. The PDF
   is the page drawn in light mode with the stylesheet named by
   `pdf_stylesheet`, printed by Chrome or Chromium with no header or footer.
   Printing keeps chart and cell colours on a white background and does not
   split a section, a table row or a label and value row across pages.

   When no Chrome or Chromium is found, the page list leaves out its PDF links
   and `KeystoneUi::Pages.pdf` raises `KeystoneUi::Pages::PrintFailed` with a
   message saying to install one or name it with `chrome_path` or `CHROME_BIN`.
   It raises the same error when Chrome cannot be started or prints nothing.
   Called from `prepare_pdf`, the error is raised inside the job, so the job
   backend's retry rules apply. Ask the developer how a failed print should
   reach the user before rescuing it.

7. To give editors a way in, link to the page list, or to one page's builder
   with a `return_to` of the screen they came from:

   ```erb
   <%= link_to "Edit page", keystone_ui_pages.manage_page_path(page, return_to: request.fullpath) %>
   ```

8. To add an element the host draws, write its component as a method that takes
   the fields as keyword arguments, make it callable from views, and register
   it:

   ```ruby
   Rails.application.config.after_initialize do
     KeystoneUi::Pages.catalog.register(key: :testimonial, name: "Testimonial", component: :testimonial,
       fields: [ { key: :quote, label: "Quote", kind: :long_text, default: "It works." } ])
     KeystoneUi::Pages.catalog.leave_out(:copy_button)
   end
   ```

   The method must be reachable in the engine's views and in any host view that
   calls `keystone_ui_page`. A `helper_method` on the base controller covers
   both. A page that holds an element the catalog no longer offers still
   draws its other elements for visitors, marks the missing one in the editor
   as no longer offered, and reports the page's id and the element's key
   through `Rails.error`, so search the pages' documents for its key before
   leaving it out.

## Conventions

- **Draw through the gem.** Use `keystone_ui_page` and `KeystoneUi::Pages.pdf`.
  Never draw `page.document` or a version's document by hand, and never print a
  PDF another way, because the gem's drawing applies bound values, conditions,
  layout and print rules together.
- **Only the live version leaves the builder.** The draft is what editors
  change. Visitors, `keystone_ui_page` and PDFs show the live version, so an
  unpublished change shows nowhere else. `keystone_ui_page` and PDFs with
  `version:` show an earlier published version, never the draft.
- **Value names are strings.** `Values.names`, the provider's hash and the
  `values:` passed to the helper and to PDFs all use the same names. The gem
  turns symbol keys into strings, so either works, but the names must match.
- **The editor's page list** at `/pages/manage/pages` shows each page's name,
  its state, and when it was last published, plus its place and access
  exception when the host names any. Each row links to Edit and Settings and has
  an Archive button, and a published page also links to View live and, when
  Chrome or Chromium is found, to its PDF. Show archived lists archived pages
  instead, each with a Restore button.
- **A page's title** is set in the builder's settings panel when nothing is
  selected, and reaches visitors when the page is published. The engine's
  public address sets it with `content_for(:title)`, so a host layout that
  shows `content_for(:title)` in its `<title>` gets it. A host drawing a page
  in its own view reads `page.live_version&.title`, which is nil when the page
  has none.
- **A paragraph's text is rich text.** Editors type it in the builder and
  link selected words with the Link button, and pasted text keeps only its
  words and links. It is stored as `{ "html" => "..." }` and cleaned each time
  it is drawn, keeping paragraphs, line breaks and links with safe addresses.
  A link to an `http` or `https` address opens in a new tab. A paragraph saved
  earlier as a plain string still draws as escaped text.
- **A feature grid's icons** are typed per feature in the builder, usually as
  an emoji. A typed icon is drawn as text, so markup or a script in it is shown
  and never run. A feature left without an icon shows the check mark.
- **A section's background and width** are set in the builder's layout panel.
  A shaded section fills the full width of the page with keystone_ui's
  `--ks-color-fill-muted` colour, and its dark value in a dark theme. A section
  with a width of `sm`, `md`, `lg` or `xl` holds its rows at keystone_ui's
  page width of that name with its page side padding, padded above and below
  from `--ks-spacing`. The page builder has no setting of its own for these:
  a host changes them through its keystone_ui theme values. A section saved
  without either draws as it did before.
- **A place's page list** at `/pages/manage/pages?place=client_report` shows
  only that place's pages, and its Create and archived links keep the place.
  With no place, or one the host does not name, the list shows every page. For
  a page with a place, the redirects after saving settings, archiving and
  restoring go to that place's list, and so does the builder's Back link unless
  the host passed its own `return_to`.
- **The New page form** at `/pages/manage/pages/new` saves a blank name from
  the place's `default_name` and a blank slug as eight random hex characters,
  and shows that name as the Name field's placeholder. A host linking to it
  with `new_manage_page_path(place: "client_report")` creates the page in that
  place and offers no place choice. The URL slug field shows unless the place
  was registered with `slug: false`. A place the host does not name in the link
  is ignored, and one posted to create is refused with the form shown again.
- **A page's settings** at `/pages/manage/pages/:id/edit` change its name, slug
  and place after it is created. A slug another page of the same owner uses, or
  a place the host does not name, is refused with a message and changes nothing.
  A changed slug moves the published page to its new address, and the old
  address is not redirected.
- **A page's state** is Draft before its first publish, Published while it has
  a live version, Unpublished once that version is taken down, and Archived.
  The builder's Unpublish button, shown next to Publish on a published page,
  takes the live version down and keeps the page's history. Archiving takes the
  live version down too and hides the page from the list. An archived page
  cannot be published, and restoring it returns it to Draft or Unpublished,
  never straight to Published. Visitors are refused every state but Published.
- **View live** draws the live version in `KeystoneUi::Pages.layout` with the
  values of the sample chosen in the builder, behind the edit check. It is
  linked from the page list and from the builder's top bar once the page is
  published.
- **History** lists every published version with its number, status and date.
  Opening one draws it, and "Restore this version as the draft" replaces the
  draft with that version's document. Restoring publishes nothing.
- **Undo and Redo** are the builder's ↶ Undo and ↷ Redo buttons. They step
  through the page's edits one at a time. The history is kept on the page, so
  it survives a reload and a publish, and a new edit after an undo clears what
  can be redone.
- **The builder's top bar** also has a Mode choice of light, dark and system
  (and custom for an editor in custom mode), a Look choice of the looks the host
  registers with Keystone UI, and a Print choice that previews the printed
  layout. None of them is saved.
- Out of scope for this local: installing the gem, its migrations, the mount and
  the layouts, which belong to `keystone_ui-pages-install`. Changing the
  builder or the built-in elements belongs in the gem, not the host app.
