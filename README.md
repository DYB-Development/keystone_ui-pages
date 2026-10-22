# keystone_ui-pages
A flow-layout page builder that draws keystone_ui elements from a versioned JSON page document

## Elements

The catalog offers these keystone_ui components as page elements by default: `button`, `progress`, `alert`, `code`, `heading`, `label` (drawn by `ui_caption`), `paragraph`, `hero`, `cta_banner`, `card`, `stat_card`, `figure`, `info`, `badge`, `copy_button`, `feature_grid`, `accordion`, `data_table`, `bar_chart`, `line_chart` and `value_list`.

A host adds its own element by registering it with a component of its own, and leaves an element out by its key:

```ruby
KeystoneUi::Pages.catalog.register(key: :testimonial, name: "Testimonial", component: :testimonial,
  fields: [ { key: :quote, label: "Quote", kind: :long_text } ])
KeystoneUi::Pages.catalog.leave_out(:copy_button)
```

### Components left out of the catalog

Each field is text, long text, an address, a number, one of a list, yes or no, a list of entries, or data the host supplies, so a component whose arguments cannot be set from those kinds is left out.

- Navigation belongs to the host's layout rather than to a page: `navbar`, `navigation`, `nav_item`, `nav_dropdown`, `bottom_nav`, `bottom_nav_item`, `breadcrumbs`, `mobile_header`, `mobile_actions`, `desktop_back_link`, `settings_link`, `action_menu`, `action_menu_item` and `theme_toggle`.
- Form inputs need a form that sends answers somewhere, and pages do not receive answers: `form`, `form_field`, `input`, `textarea`, `select`, `multi_select`, `checkbox_row`, `radio_card`, `option_card`, `color_picker`, `file_upload` and `column_picker`.
- Page frames and wrappers hold other components, and elements do not hold other elements: `page`, `form_page`, `show_page`, `page_header`, `section`, `grid`, `panel`, `card_link`, `modal` and `disclosure`.
- These take structured data whose shape the catalog does not describe yet: `tab_switcher`, `swipe_deck`, `chart_card`, `funnel`, `pipeline`, `bucket`, `bucket_series`, `breakdown` and `calculation`.

## Theme, look and styles

A live page is drawn inside the host's layout, and the builder inside the host's editor layout. Both follow the host app's keystone theme, look and styles when each layout:

- marks its `html` tag with `<%= keystone_theme_attributes %>`, which sets the mode and the look for the person viewing it, and
- links the host's stylesheet, which carries keystone_ui-styles, the host's looks and colours, and the host's own styles.

A host links an editor to the builder at `/pages/manage/pages/:id`, and can add `return_to` with an address on its own site, such as `?return_to=/admin/marketing`. The builder's Back link returns there, even after the builder reloads from Publish. With no `return_to`, or one on another site, Back goes to the list of pages.

The builder's ↶ Undo and ↷ Redo buttons step through the page's edits one at a time. The history is kept with the page, so it survives a reload and a publish, and a new edit after an undo clears what can be redone. It needs the engine's edit history migration, which a host installs with its other migrations.

The builder opens in the editor's own mode and look. Its top bar has a Mode choice of light, dark and system, plus custom for an editor in custom mode, and a Look choice of the looks the host registers. Each choice redraws the page in the builder, so an editor can see every version a visitor may get, and neither is saved.

## Printing and PDFs

A printed page has a white background, keeps the colours of its charts and shaded cells, and does not split a section, a table row or a label and value row across pages. The builder's Print choice previews that layout.

A host gets a published page as a PDF, drawn with the values it passes, and gets back a record whose `file` is kept in Active Storage:

```ruby
pdf = KeystoneUi::Pages.pdf(page, values: { "client_name" => "Acme" })
pdf.file # an Active Storage attachment, ready to download, link or email
```

Asking again for the same published version and values returns the kept file without printing it again. A newly published version, or different values, makes a new one. To have it ready before anyone downloads it, such as when an invoice is created, make it in a background job:

```ruby
KeystoneUi::Pages.prepare_pdf(page, values: { "client_name" => "Acme" })
```

Publishing a page that uses no host values makes its PDF straight away, since it looks the same for everyone.

The PDF is printed by Chrome or Chromium on the server, from the page drawn with the host's compiled stylesheet, so it looks exactly as the page does. The host needs:

- Active Storage set up, which keeps the files.
- Chrome or Chromium installed. Set `KeystoneUi::Pages.chrome_path` to it, or set `CHROME_BIN`, or install it in a usual place, such as `/usr/bin/chromium`. Chrome runs hidden on the server, so nobody needs it as their browser. When none is found, the page list leaves out its PDF links and asking for a PDF raises an error saying how to name one.
- Its stylesheet served by Propshaft. `KeystoneUi::Pages.pdf_stylesheet` names it and defaults to `tailwind.css`.

## Reporting views and clicks to the host

The gem keeps no record of who views a page or what they click. A host that wants to know registers a handler on the place, and the gem hands each view and click to it:

```ruby
KeystoneUi::Pages.register_place("marketing", label: "Marketing site", events: ->(event) { PageView.record(event) })
```

The handler receives a `KeystoneUi::Pages::Event` holding `page`, `place`, `kind` (`"view"` or `"click"`), `element` and `request`. For a click, `element` is the id of the page element the clicked link or button sits in, and for a view it is nil. Deciding what counts as a visit, honouring Do Not Track and leaving out crawlers is the handler's job.

A page opened at its public address, or drawn with `keystone_ui_page` in a host view, sends its view from the visitor's browser once it loads. View live in the builder and a printed PDF send nothing. That only happens when the live version is drawn and the page's place has a handler. Drawing an older version by number, or a page from a place with no handler, sends nothing. The helper puts its script in `content_for :head`, so the host layout must call `yield :head` inside `<head>`. The same pages send a click on any link, button or card link, including one that opens another page, and a click anywhere else sends nothing. Views and clicks are sent without a form token and the gem sets no cookie.

## Trying it locally

The test app runs the builder in development with sample places, access exceptions and a view check, so each case below can be shown without a host app:

```sh
npm ci
cd test/dummy
bin/rails db:prepare
bin/rails tailwindcss:build
bin/rails server -p 3100
```

Open `http://localhost:3100/pages/manage/pages` and create pages with Create, choosing a place for each: Marketing site, Client portal or Paid content. Publish each one from the builder.

Each published page is at `http://localhost:3100/pages/<address>`, and the links above it switch who you are acting as. A page that refuses you shows only a refusal, so switch from another page or go to `/demo/visitor/visitor`, `/demo/visitor/signed_in_client` or `/demo/visitor/purchased_client`.

| Case | Do this | You see |
|---|---|---|
| A visitor is refused a client portal page | Act as Anonymous visitor and open a Client portal page | "This page is not available" |
| A signed-in client sees it | Act as Signed-in client and open the same page | The page |
| Paid content needs a purchase | Act as Signed-in client, then Client who purchased, and open a Paid content page | A refusal, then the page |
| An exception lets a page through | Choose Public preview under Access exception in the builder, then act as Anonymous visitor | The page |
| Unpublishing takes a page down | Choose Unpublish in the builder and reload the page's address | A refusal |
| Archiving hides a page | Choose Archive in the page list, then Show archived and Restore | The page leaves the list and comes back as Unpublished |

### Showing different content to each visitor

The test app also gives each published page values for whoever you are acting as: `signed_in` and `purchased`, each `yes` or `no`, and `client_name` for a client. To build a page that changes with them:

1. Add a Button labelled Buy and set its Show when to Purchased equals `no`.
2. Add a Button labelled Open and set its Show when to Purchased equals `yes`.
3. Add a section holding a client offer and set its Show when to Signed in equals `yes`.
4. Bind a text setting to Client name and give it a fallback such as `Welcome`.

The builder's Preview with choice offers the same three visitors, so the canvas shows each version before you publish.

| Acting as | Buttons | Client offer | Bound text |
|---|---|---|---|
| Anonymous visitor | Buy | Hidden | The fallback |
| Signed-in client | Buy | Shown | Acme |
| Client who purchased | Open | Shown | Acme |

An anonymous visitor never sees Open, since nobody can know what an anonymous visitor owns.

None of this applies in the test environment or to a host app, which names its own places, exceptions, view check and visitor values.
