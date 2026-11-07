---
name: keystone_ui-pages-develop
description: Use PROACTIVELY for working with Keystone UI Pages in a host app — its settings, host values, drawing a page in the host's own screens, making PDFs with Chrome or drawn in Ruby, linking editors to the builder, showing a host's ordered set of pages such as a funnel in the builder and letting staff add pages to it, and adding or leaving out catalog elements — MUST BE USED instead of hand-building page drawing or PDF printing.
tools: Bash, Read, Write, Edit, Grep
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
PDF, give editors a link to the builder, let staff build a host's ordered
set of pages side by side and add pages to it, supply values to pages, add a
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
  `/pages/:slug`, whatever the view check says. `events:` takes a handler the
  gem calls for each accepted view of the place's live pages; a place with no
  handler reports nothing. `submissions:` takes a handler the gem calls with a
  `KeystoneUi::Pages::Submission` for each accepted form submission from the
  place's pages; a place with no handler refuses every submission as not found.
  `leaves_out:` takes catalog keys the place does not offer, such as
  `[ :form ]`; every other catalog element is offered there, including ones
  registered later. The builder's element list and adding an element use only
  what the place offers, and moving a page to a place that leaves out an
  element it holds is refused on its settings page. A key no catalog element
  has raises an `ArgumentError` when the app boots, checked after every
  initializer and `after_initialize` block has run, and so does a registered
  place that offers the Form element without a `submissions:` handler.
  Registered places are offered alongside any set with `places =`, and
  `places = nil` clears both. `listed: false` keeps the place out of the
  editor's screens: the page list leaves out its pages unless it is opened with
  that place, and the New page form and creating a page in it are refused, while
  the place choices on the New page and settings forms do not offer it. Use it
  for a place whose pages the host makes itself. `sequence_method:` names a
  method that answers the place's sequences, described under the sequence
  screen below. A place with none refuses its sequence screen.
  `adds_page_method:` names a method the gem calls after a page is added to one
  of the place's sequences, described under the Add page form below. A place
  with a `sequence_method:` and no `adds_page_method:` raises an
  `ArgumentError` when the app boots, checked with the other place checks.
  `next_page_method:` names a method the gem calls with the page being shown,
  on the controller drawing it, that answers the address the visitor goes to
  next, or nil. Only a place naming one offers the Next page element and the
  `next_page` choice under a form's After submitting. The button is filled in
  on each visit after the cached drawing is read, is left out when the method
  answers nil, and is never in a PDF. A form set to `next_page` sends the
  visitor to the answer, or shows its thank-you message when the answer is nil.
  `publishes_sequence_method:` names a method the gem calls with a sequence's
  key when staff press the Publish button in the sequence's list. Only a place
  naming one shows the button, and adding a page never calls it. Raise
  `KeystoneUi::Pages::SequencePublishRefused` with a reason to refuse, and staff
  see the reason on the sequence screen. Any other error is not caught.
  `removes_page_method:` names a method the gem calls with a sequence's key and
  the page staff confirmed removing. Only a place naming one shows Remove in the
  sequence's list. The gem archives the page and calls the method in one
  transaction, so a page stays unarchived when the method raises, and the method
  has to take the page out of what `sequence_method:` answers.
- **Form submissions handed to the host**: `POST /pages/:slug/versions/:number/forms/:element_id`
  finds the form in that version, live or older, and calls the place's
  `submissions:` handler with a `Submission` holding `page`, `version`,
  `form_name`, `element_id`, `values` (only the field names that version's form
  lists, with each checkbox as `true` or `false`), `request` and `bot`. Every
  form carries a trap field people cannot see, reach by keyboard, hear or have
  autofilled; a submission that fills it arrives with `bot: true`, and the
  visitor still gets the normal answer, so the handler decides what to drop.
  A handler that raises is reported through `Rails.error` with `page_id` and
  `form_name`, and the visitor gets the form back in place, with their values,
  under a message saying it was not sent, never the thank-you or the address.
- `KeystoneUi::Pages.turnstile_site_key = "..."` — the Cloudflare Turnstile
  site key. With it set, every form shows Cloudflare's widget and a page holding
  a form loads `https://challenges.cloudflare.com/turnstile/v0/api.js` through
  `content_for :head`, so the host's content security policy must allow it.
  Unset, nothing is loaded from Cloudflare.
- `KeystoneUi::Pages.turnstile_secret_key = "..."` — the Cloudflare Turnstile
  secret key. With both keys set, each submission's token is confirmed with
  Cloudflare, and one it does not confirm arrives with `bot: true` while the
  visitor gets the normal answer. Unset, no submission is sent to Cloudflare. It keeps the host's forgery protection, refuses a
  visitor the view check refuses the way the page is refused, and answers 404
  when the form is not in the version or the place has no handler. A required
  field left empty, an email field holding no email address, or a choice
  that is not one of the field's choices, or a value longer than its kind
  allows (text and choice 200 characters, email 254, long text 5000, checkbox
  1), is refused with
  422 and the form drawn again in its frame with an error under each failed
  field and the visitor's values, never reaching the handler. It otherwise answers
  with the form's thank-you message in a `turbo-frame` named after the form,
  inside the host's page layout, so a page running Turbo swaps only the form.
  A form set to `address` answers a successful submission with a 303 redirect
  there, after the handler runs. A page whose drawing holds a form adds the
  forms script to `content_for :head`, which turns that redirect into a whole
  page visit on a page running Turbo; refusals still answer in place.
  The gem stores nothing.
- **Views and clicks handed to the host**: a page opened at `/pages/:slug` whose place has
  a handler loads the reporting script, which sends its view once it loads and
  a click on any link or button with the id of the element it sits in. Each
  element on a live drawing carries its id as `data-page-element`. The script
  also fires `keystone-ui-pages:view` (`detail`: `slug`, `place`) and
  `keystone-ui-pages:click` (`detail`: `slug`, `place`, `element`, `href`) on
  `document`, whatever the event address answers, for a tag in the host layout.
  View live and PDFs send nothing. `POST /pages/:slug/events` calls the page's
  place's `events:` handler with a `KeystoneUi::Pages::Event` holding `page`,
  `place`, `kind` (`"view"` or `"click"`), `element` (the element id for a
  click, nil for a view) and `request`. The gem stores nothing;
  what is kept, counted or shown is the host's to decide. The handler runs inside
  the event request, so slow work belongs in a job it enqueues. A handler that
  raises is reported through `Rails.error` with `page_id` and `kind`, and the
  browser still gets 204. An event whose `kind` is given and is not `view` or
  `click` is refused, and so is a click whose `element` is missing or not on the
  live version; a request with no `kind` is a view. A prerendered page sends its
  view when it is opened. It needs no form
  token. It is refused the way the public page refuses a page when the page has
  no live version, is another owner's, fails the view check, or its place has
  no handler.
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
  compiled stylesheet in Propshaft. Defaults to `"tailwind.css"`. The Chrome
  drawing writes it into every PDF, and a name Propshaft cannot find prints
  with no styles. The Ruby drawing reads Keystone UI's `--ks-` tokens and the
  `--text-` size and `--tracking-` letter spacing tokens from it, so a name
  Propshaft cannot find, or a stylesheet missing a token the drawing reads,
  makes the Ruby drawing raise a `KeyError` naming the token.
- `KeystoneUi::Pages.pdf_drawing = :ruby` — how PDFs are drawn: `:chrome` (the
  default) prints the page's HTML with Chrome or Chromium, and `:ruby` draws
  the page in Ruby with Prawn from its sections, rows, columns and elements,
  with no Chrome needed. A string works too. The Ruby drawing honours bound
  values and show-when conditions and lays out each row's columns side by side
  at their widths, with no host print rules. It takes Keystone UI's look from
  the `pdf_stylesheet`'s `--ks-` tokens, in light mode and in the host's
  default Keystone UI look: values set inside `@media` rules or under any
  selector other than `:root`, `:host`, `html` or the default look's
  `[data-look=...]` are left out, a host's own value outside a layer wins over
  Keystone UI's layered one, and the look's value wins over the root's. Rows
  in a section sit six `--ks-spacing` steps apart and elements in a column four,
  where `rem` counts as 12 points, `px` as 0.75 and `pt` as 1. An `em` counts
  as 12 points, except in a letter spacing token, where it counts as the size
  of the text it spaces. A line height token, such as `--text-sm--line-height`
  or `--leading-relaxed`, is read as a number or a `calc(a / b)` and counts the
  text sizes each line takes, and the space it adds is split above and below
  the text. A colour token must be an `oklch()` colour or a hex colour of
  three or six digits, and a three-digit one prints as the six-digit colour it
  names. Each element draws through the `pdf:` drawing given to
  `catalog.register`. Of the built-in elements `heading`, `label`,
  `paragraph`, `alert`, `value_list`, `button` and `accordion` have one.
  `form`, `copy_button` and `next_page` have a drawing that draws nothing, so
  they are left out of the PDF and do not raise. Every other built-in element
  raises `NoPdfDrawing`.
- **The built-in elements in the Ruby drawing.**
  - A heading draws its text at `--text-lg`, `--text-2xl` or `--text-4xl` for
    `sm`, `md` or `lg` in `--ks-font-heading` at `--ks-font-weight-heading` and
    `--ks-color-text`, at that size's `--line-height` token. Its note draws under
    it at `--text-sm` in `--ks-color-text-muted`, at `--text-sm--line-height`.
  - A label draws its text in capitals at `--text-xs` in `--ks-font-body` at
    `--ks-font-weight-strong` and `--ks-color-text-muted`, with
    `--tracking-wider` letter spacing, at `--text-xs--line-height`.
  - A paragraph draws each of its stored paragraphs at `--text-base` in
    `--ks-font-body` and `--ks-color-text`, at `--leading-relaxed`. Line breaks
    and links are kept, and a link opens its address when clicked in the PDF.
    Bold and italic marks stored in the text print bold and italic. Scripts,
    styles and every other tag are dropped. A paragraph saved as a plain string
    draws as one paragraph.
  - An alert draws on a rounded box the width of its column, filled with
    `--ks-color-<tone>-50`, padded by four `--ks-spacing` steps, with corners of
    0.75 times `--ks-radius-surface`. The tone is the alert's type, with `error`
    read as `danger`. Its title, when set, draws at `--text-base` and
    `--ks-font-weight-heading` at the line height the stylesheet's `html` rule
    gives, then one `--ks-spacing` step. Its message draws at `--text-sm` at
    `--text-sm--line-height`. Both are in `--ks-color-<tone>-800`. Whether it
    can be dismissed has no effect on paper.
  - A label and value list draws each row with two `--ks-spacing` steps above
    and below, and a line of `--ks-border-width` in `--ks-color-border` between
    rows. The label takes two fifths of the width and the value the rest, four
    `--ks-spacing` steps apart. Labels and values draw at `--text-base` at the
    line height the stylesheet's `html` rule gives. A label is in
    `--ks-color-text-secondary` and a value in `--ks-color-text`. A note draws
    under its label at `--text-xs` in `--ks-color-text-muted`, at
    `--text-xs--line-height`. A blank value draws the row's fallback text. With
    the list's values set to `end`, values draw against the right edge. A total
    row draws its label, note and value at `--ks-font-weight-strong`, with its
    label in `--ks-color-text`.
  - A button draws its label at `--text-base` in `--ks-font-body` at
    `--ks-font-weight-strong` and `--ks-color-on-accent`, at
    `--text-base--line-height`, on a rounded box filled with
    `--ks-color-accent`. The box is padded by four `--ks-spacing` steps across
    and two down, has corners of one `--ks-radius-control`, and is outlined with
    `--ks-border-width-control` in `--ks-color-on-accent`. It is as wide as the
    label and its padding, and never wider than its column. A button with an
    address opens it when the box is clicked in the PDF.
  - An accordion draws every question with its answer shown under it, with no
    arrow. Each item draws in a rounded box with no fill, outlined with
    `--ks-border-width` in `--ks-color-border-subtle`, padded by six
    `--ks-spacing` steps across and four down, with corners of 1.5 times
    `--ks-radius-surface`, and items sit four `--ks-spacing` steps apart. The
    question draws at `--text-base` in `--ks-font-body` at
    `--ks-font-weight-heading` and `--ks-color-text-display`, at the line height
    the stylesheet's `html` rule gives. The answer draws four `--ks-spacing`
    steps under it at `--text-sm` in `--ks-color-text-body`, at
    `--text-sm--line-height`. An accordion with no items draws nothing.
  - The form, the copy button and the Next page button draw nothing in the
    Ruby drawing. The four `--ks-spacing` steps between elements in a column
    are still kept around each of them.
- **Fonts in the Ruby drawing.** A font token is read as a list of families,
  and `inherit` takes the `html` element's `font-family`. The first family the
  stylesheet loads with `@font-face` is used. A list with no such family prints
  in Helvetica. A loaded family prints from a TrueType copy of the files its
  `@font-face` rules load for regular, bold and italic text, found under the
  same address with a `.ttf` ending, in `public/` or among the files Propshaft
  serves. When any of the three copies is not served, `KeystoneUi::Pages.pdf`
  raises `KeystoneUi::Pages::PrintFailed` naming the font and the address it
  looked for. A weight of 600 or more prints bold.
- `KeystoneUi::Pages.ruby_pdf_drawing?` — true when `pdf_drawing` is `:ruby` or
  `"ruby"`. Use it to decide whether to offer a PDF without checking for
  Chrome.
- `KeystoneUi::Pages::NoPdfDrawing` — raised by `KeystoneUi::Pages.pdf` under
  the Ruby drawing when the page holds a shown element whose catalog entry has
  no `pdf:` drawing. Its message names the element. It is a
  `KeystoneUi::Pages::PrintFailed`, so a rescue of `PrintFailed` catches it.
  Nothing is kept when it is raised. An element hidden by a show-when condition
  for the values given is not drawn and does not raise.

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
  When it draws the live version of a page whose place has an `events:`
  handler, it adds the reporting script to `content_for :head` and the page's
  view is sent from the browser once it loads, so the host layout must call
  `yield :head`. An older version drawn by number sends nothing.
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
- `/manage/sequences/:place/:key` under the engine's mount path — the builder
  for one of the host's sequences, at `/pages/manage/sequences/funnel/abc123`,
  or `keystone_ui_pages.manage_sequence_path("funnel", "abc123")` from the
  host. It runs behind the edit check. The engine calls the place's
  `sequence_method:` with the key and draws the builder for the sequence's
  first page, with the sequence's title and its pages numbered from 1 beside it
  and the page being built marked. Choosing a page in that list opens it with
  `page_id:` added to the address. A sequence with no pages, or a `page_id:`
  not among its pages, shows an empty page area beside the list. The Back link
  goes to the sequence's `back_url`. Publish, Unpublish and the History screen's
  link back to the builder return to the same page on the sequence screen. A nil
  answer, or a place with no `sequence_method:`, gets the host's refusal. The
  list has an Add page button, shown with or without pages in the sequence.
- `/manage/sequences/:place/:key/pages/new` under the engine's mount path — the
  Add page form, or `keystone_ui_pages.new_manage_sequence_page_path("funnel", "abc123")`
  from the host. It runs behind the edit check and asks for a name, with
  the place's next default name, such as "Step 3", as its placeholder, and for
  Start from: Blank page, or a copy of any page in the same place that
  `owner_method`'s record owns and that is not archived, including pages of
  other sequences. A copy takes that page's document and nothing else, starts
  as a draft, and changes apart from it afterwards. Creating
  makes a page with the name given, or the default name when it is left blank,
  in the sequence's place, with the sequence's key, owned by `owner_method`'s
  record, and with a random slug. The engine then calls the place's
  `adds_page_method:` on the editor's controller with three arguments: the
  sequence's key, the new page, and the page that was open on the sequence
  screen when Add page was pressed, or nil when no page of the sequence was
  open, as when it had no pages. Then
  it opens the sequence screen with `page_id:` set to the new page. The form and
  creating are refused the same way as the sequence screen when the sequence
  method answers nil, and no page is made.
- `KeystoneUi::Pages::Sequence.new(title:, pages:, back_url:, screen_url: nil)` —
  what a sequence method answers. `title:` is the heading shown above the list.
  `pages:` is an array of `KeystoneUi::Pages::Page` records in the order a
  visitor goes through them, and the list shows them in exactly that order,
  since the gem stores no order, each with a badge saying whether it is a
  draft, published or unpublished. `back_url:` is where Back goes. These three
  are required. `screen_url:` is optional: the address of the host's own screen
  for the sequence, such as where its order is changed, and when given the list
  shows a Flow link to it.

### The element catalog

- `KeystoneUi::Pages.catalog.register(key:, name:, component:, fields:, body: nil, icon: nil, group: nil, align: nil, placed: false, pdf: nil)`
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
  `placed: true` also passes `element_id:` and `version:` (nil in the builder)
  to the method, which the Form element uses to build its address.
  `pdf:` is the element's Ruby PDF drawing, used only when `pdf_drawing` is
  `:ruby`: a callable taking the drawing surface and a hash of the element's
  field values keyed by symbol, with bound values filled in and each unset
  field at its `default:`. A `:list` field arrives as an array of hashes with
  symbol keys, each blank part filled with its entry's `default:`. Every call
  on the surface draws below what was drawn before it in the same column, and
  reads the tokens as the Ruby drawing's look describes. The surface has seven
  calls.
  - `text(content, size:, font: "--ks-font-body", weight: nil, color: "--ks-color-text", uppercase: false, tracking: nil, align: nil, leading: nil)`
    writes the content. `size:` names a length token, such as `"--text-sm"`,
    never a number of points. `font:`, `weight:` and `color:` name `--ks-`
    tokens, with no weight meaning regular. `uppercase: true` writes the
    content in capitals. `tracking:` names a letter spacing token, such as
    `"--tracking-wider"`, and no tracking means none. `align:` is `:left` (the
    default), `:center` or `:right`. `leading:` names a line height token, such
    as `"--text-sm--line-height"`, or `"line-height"` for the line height the
    stylesheet's `html` rule gives, and no leading means the font's own height.
  - `rich_text(runs, size:, font: "--ks-font-body", color: "--ks-color-text", leading: nil)`
    writes one paragraph from an array of runs. Each run is a hash with
    `text:`, and optionally `link:` (an address the run opens when clicked),
    `bold: true` and `italic: true`. A run whose text is `"\n"` breaks the line.
  - `box(padding:, radius:, fill: nil, border: nil) { ... }` draws a rounded
    box the width of the column, as tall as what the block draws, and draws the
    block inside it. `padding:` is a length token and a number of steps, such
    as `[ "--ks-spacing", 4 ]`, or a token and two numbers of steps, across and
    then down, such as `[ "--ks-spacing", 6, 4 ]`. `radius:` is a length token
    and a number of steps for the corners. `fill:` names a colour token, and no
    fill leaves the box unfilled. `border:` is a hash of `width:`, a length
    token for the outline's thickness, and `color:`, a colour token, such as
    `{ width: "--ks-border-width", color: "--ks-color-border-subtle" }`. The
    outline is drawn inside the box and its thickness is added to the padding.
    A thickness of zero draws no outline, and no border means none.
  - `boxed_text(content, size:, fill:, padding:, radius:, border: nil, link: nil, font: "--ks-font-body", weight: nil, color: "--ks-color-text", leading: nil)`
    writes the content on a rounded box as wide as the content and its padding,
    and never wider than the column. `size:`, `font:`, `weight:`, `color:` and
    `leading:` work as they do for `text`. `fill:` names the box's colour token,
    and `padding:`, `radius:` and `border:` work as they do for `box`. `link:`
    is an address the whole box opens when clicked in the PDF, and no link
    means none.
  - `rule(width:, color:)` draws a line across the column. `width:` names a
    length token for its thickness and `color:` a colour token.
  - `space(token, steps)` moves down by that many steps of a length token, such
    as `space("--ks-spacing", 2)`.
  - `row(widths, gap: nil) { |index| ... }` splits the column side by side.
    `widths` lists each part's share of the column, such as
    `[ Rational(2, 5), Rational(3, 5) ]`. `gap:` is a length token and a number
    of steps put before every part but the first. The block runs once per part
    with its index, every part starts at the same height, and drawing continues
    below the tallest.

  A token the host's stylesheet does not set raises a `KeyError` naming it. An
  element registered without `pdf:` makes the Ruby drawing raise
  `NoPdfDrawing` for any page showing it.
- The built-in Form element (`:form`) holds a form name, a list of fields (each
  a label, a field name, a kind of `text`, `email`, `long_text`, `choice` or
  `checkbox`, the choices of a `choice` field separated by commas, and whether
  it is required), a submit label, a thank-you message, and what happens after a
  successful submission: `thank_you` (the default) or `address`, which sends the
  visitor to the address the editor sets. A published form
  posts to `POST /pages/:slug/versions/:number/forms/:element_id`. Its drawing
  is cached with a placeholder token, and each request puts in the visitor's
  own forgery token, so the host's forgery protection stays on. A published form
  is hidden in print, so no PDF and no page printed from the browser shows it.
- `KeystoneUi::Pages.catalog.leave_out(:copy_button)` — removes elements from
  the palette by key. Takes several keys.

Each entry in `fields:` is a hash. Its `key:` is the keyword the component
receives and its `label:` is the label in the builder's field panel. Its
`kind:` is one of `:text` (the default when no kind is given), `:long_text`,
`:rich_text`, `:address`, `:number`, `:one_of`, `:yes_or_no`, `:list` or
`:data`. A `:rich_text` field is edited the way a paragraph is and arrives as
`{ "html" => "..." }`, or as a plain string when it was saved as one, such as
its `default:`. The HTML is stored as the builder sent it, so a host component
must sanitize it before drawing it. A number
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

   The page must be published, since only the live version is printed.

   Which drawing to use is the developer's decision, so ask before setting
   `pdf_drawing`. Chrome draws every element with the host's styles but needs
   Chrome or Chromium on the server. Ruby needs no Chrome but draws only
   elements with a `pdf:` drawing, in Keystone UI's fonts, weights, text sizes,
   line heights, letter spacing, colours, fills, borders and spacing read from
   the host's stylesheet. Of the built-in elements it draws headings, labels,
   paragraphs, alerts, label and value lists, buttons and accordions, and it
   leaves forms, copy buttons and Next page buttons out of the PDF.

   With `:chrome`, the PDF is the page drawn in light mode with the stylesheet
   named by `pdf_stylesheet`, printed with no header or footer. Printing keeps
   chart and cell colours on a white background and does not split a section,
   a table row or a label and value row across pages. When no Chrome or
   Chromium is found, the page list leaves out its PDF links and
   `KeystoneUi::Pages.pdf` raises `KeystoneUi::Pages::PrintFailed` with a
   message saying to install one or name it with `chrome_path` or `CHROME_BIN`.
   It raises the same error when Chrome cannot be started or prints nothing.

   With `:ruby`, the page list shows its PDF links whether or not Chrome is
   found. Before switching, check that every element on the pages that will be
   printed has a `pdf:` drawing, and give a host-registered element one with
   `pdf:` on `catalog.register`. A page showing an element without one raises
   `NoPdfDrawing`, including from the PDF job queued when such a page is
   published with no host values. Also check the fonts the stylesheet's
   `--ks-font-heading` and `--ks-font-body` name: a family loaded with
   `@font-face` needs a `.ttf` copy served beside each of its files, or every
   PDF raises `PrintFailed` naming the missing file. If the host has no `.ttf`
   files for its font, ask the developer where to get them rather than
   converting or replacing the font.

   Called from `prepare_pdf`, either error is raised inside the job, so the job
   backend's retry rules apply. Ask the developer how a failed print should
   reach the user before rescuing it.

7. To give editors a way in, link to the page list, or to one page's builder
   with a `return_to` of the screen they came from:

   ```erb
   <%= link_to "Edit page", keystone_ui_pages.manage_page_path(page, return_to: request.fullpath) %>
   ```

8. To let staff build a host's own ordered set of pages side by side, such as
   the steps of a funnel:

   ```ruby
   KeystoneUi::Pages.register_place("funnel", label: "Funnel", listed: false, default_name: "Step",
     sequence_method: :funnel_sequence, adds_page_method: :add_funnel_page)
   ```

   Both methods are required together. Write them on the base controller. The
   sequence method takes the key from the address and answers a `Sequence`, or
   nil to refuse:

   ```ruby
   def funnel_sequence(key)
     funnel = current_team.funnels.find_by(key: key)
     return unless funnel

     KeystoneUi::Pages::Sequence.new(title: funnel.name, pages: funnel.pages_in_order, back_url: funnel_path(funnel))
   end
   ```

   The engine does not limit a sequence's pages to `owner_method`'s owner, so
   the method must find the sequence through the current owner and answer nil
   for any other.

   The add page method takes the key, the page the gem just made and the page
   that was open, which may be nil. It records the new page in the host's order,
   so the next answer from the sequence method includes it:

   ```ruby
   def add_funnel_page(key, page, open_page)
     funnel = current_team.funnels.find_by!(key: key)
     funnel.insert_page(page, after: open_page)
   end
   ```

   Where the new page goes, such as after the open page or at the end, is the
   developer's decision, so ask before choosing. A page the method does not
   record is still made, keeps the sequence's key and its place, but is left out
   of the list and the sequence screen opens on an empty page area. A method
   that raises leaves the page made and the error unhandled.

   Staff add pages with the Add page button. The host can also make a page
   itself, with the place and the sequence's key, and then record it in its
   order:

   ```ruby
   KeystoneUi::Pages::Page.create!(owner: current_team, place: "funnel", sequence_key: funnel.key)
   ```

   `sequence_key` is set only when the page is made. A later update that
   changes it raises `ActiveRecord::ReadonlyAttributeError` in an app on Rails
   7.1 defaults or later, and is ignored otherwise. The host keeps the order and
   answers it in `pages:`. Which records a sequence is and how its pages are
   ordered is the developer's decision, so ask before choosing. Then link staff
   to `keystone_ui_pages.manage_sequence_path("funnel", funnel.key)`.

9. To add an element the host draws, write its component as a method that takes
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
   both. When the host uses the Ruby drawing, also pass `pdf:`, such as
   `pdf: ->(surface, fields) { surface.text(fields[:quote], size: "--text-sm", color: "--ks-color-text-muted", leading: "--text-sm--line-height") }`.
   Build it from the surface's calls in the Interface, with the same tokens
   the component's Keystone UI classes use on screen.
   Name only tokens the host's stylesheet sets, since a missing one raises a
   `KeyError` naming it. A page that holds an element the catalog no longer offers still
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
  `pdf_drawing` is `:ruby` or Chrome or Chromium is found, to its PDF. Show archived lists archived pages
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
- **A sequence's order is the host's.** The gem stores no order and no
  membership beyond each page's `sequence_key`. The sequence screen shows
  exactly the pages the sequence method answers, in that order, so removing or
  reordering pages is done in the host's own records. A page added with Add
  page joins the order only through the add page method.
- **The builder's top bar** also has a Mode choice of light, dark and system
  (and custom for an editor in custom mode), a Look choice of the looks the host
  registers with Keystone UI, and a Print choice that previews the printed
  layout. None of them is saved.
- Out of scope for this local: installing the gem, its migrations, the mount and
  the layouts, which belong to `keystone_ui-pages-install`. Changing the
  builder or the built-in elements belongs in the gem, not the host app.
