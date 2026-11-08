# keystone_ui-pages
A flow-layout page builder that draws keystone_ui elements from a versioned JSON page document

## Elements

The catalog offers these keystone_ui components as page elements by default: `button`, `progress`, `alert`, `code`, `heading`, `label` (drawn by `ui_caption`), `paragraph`, `hero`, `cta_banner`, `card`, `stat_card`, `figure`, `info`, `badge`, `copy_button`, `feature_grid`, `accordion`, `form` (drawn by the gem's own form helper), `data_table`, `bar_chart`, `line_chart` and `value_list`.

A host adds its own element by registering it with a component of its own, and leaves an element out by its key:

```ruby
KeystoneUi::Pages.catalog.register(key: :testimonial, name: "Testimonial", component: :testimonial,
  fields: [ { key: :quote, label: "Quote", kind: :long_text } ])
KeystoneUi::Pages.catalog.leave_out(:copy_button)
```

### Components left out of the catalog

Each field is text, long text, an address, a number, one of a list, yes or no, a list of entries, or data the host supplies, so a component whose arguments cannot be set from those kinds is left out.

- Navigation belongs to the host's layout rather than to a page: `navbar`, `navigation`, `nav_item`, `nav_dropdown`, `bottom_nav`, `bottom_nav_item`, `breadcrumbs`, `mobile_header`, `mobile_actions`, `desktop_back_link`, `settings_link`, `action_menu`, `action_menu_item` and `theme_toggle`.
- Form inputs need a form that sends answers somewhere, and pages do not receive answers: `form`, `form_field`, `input`, `textarea`, `select`, `multi_select`, `checkbox_row`, `radio_card`, `option_card`, `color_picker`, `file_upload`, `column_picker` and `search_select`.
- Page frames and wrappers hold other components, and elements do not hold other elements: `page`, `form_page`, `show_page`, `page_header`, `section`, `grid`, `panel`, `card_link`, `modal` and `disclosure`.
- These take structured data whose shape the catalog does not describe yet: `tab_switcher`, `swipe_deck`, `chart_card`, `funnel`, `pipeline`, `bucket`, `bucket_series`, `breakdown` and `calculation`.
- These are new in keystone_ui and not offered yet: `picture`, `mobile_action`, `sortable_list`, `empty_state` and `link_list`.

## Theme, look and styles

A live page is drawn inside the host's layout, and the builder inside the host's editor layout. Both follow the host app's keystone theme, look and styles when each layout:

- marks its `html` tag with `<%= keystone_theme_attributes %>`, which sets the mode and the look for the person viewing it, and
- links the host's stylesheet, which carries keystone_ui-styles, the host's looks and colours, and the host's own styles.

A host links an editor to the builder at `/pages/manage/pages/:id`, and can add `return_to` with an address on its own site, such as `?return_to=/admin/marketing`. The builder's Back link returns there, even after the builder reloads from Publish. With no `return_to`, or one on another site, Back goes to the list of pages.

The builder's ↶ Undo and ↷ Redo buttons step through the page's edits one at a time. The history is kept with the page, so it survives a reload and a publish, and a new edit after an undo clears what can be redone. It needs the engine's edit history migration, which a host installs with its other migrations.

The builder opens in the editor's own mode and look. Its top bar has a Mode choice of light, dark and system, plus custom for an editor in custom mode, and a Look choice of the looks the host registers. Each choice redraws the page in the builder, so an editor can see every version a visitor may get, and neither is saved.

## Printing and PDFs

A printed page has no forms, a white background, keeps the colours of its charts and shaded cells, and does not split a section, a table row or a label and value row across pages. The builder's Print choice previews that layout.

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

A host with no Chrome can have the PDF drawn in Ruby instead, from the page's sections, rows, columns and elements:

```ruby
KeystoneUi::Pages.pdf_drawing = :ruby
```

It defaults to `:chrome`. The Ruby drawing needs no Chrome, so the page list shows its PDF links either way. Each element draws through its own PDF drawing, given to `catalog.register` as `pdf:`, and a page holding an element without one raises `KeystoneUi::Pages::NoPdfDrawing`, a `PrintFailed`, naming the element. So far the heading, label, paragraph, alert, label and value list, button, accordion and table elements have PDF drawings, and the form, copy button and Next page elements have drawings that leave them out of the PDF. A paragraph prints its paragraphs, line breaks and links, and a link opens its address when clicked in the PDF. A button prints as its label, and one with an address opens it when clicked in the PDF. An accordion prints every question with its answer shown beneath it, as the page shows an opened question, without the arrow beside the question. Bold and italic marks stored in a paragraph print bold and italic, though the builder does not offer them yet.

A table prints its heading row, then one row per item, then its total row when it has one. Each column is as wide as its widest cell when the table has room, and the table fills the width of the column it sits in. When it has no room, a column whose text fits its share of the width stays on one line and the text in the other columns wraps within its cells, though never narrower than its longest word. A column set to end, and the last column unless it is set to start, is aligned to the right. A table grouped by a key prints each group's name above its rows, with the group's subtotals when they are given, and keeps the group's name on the same page as its first row. A table longer than a page continues on the next page with its heading row printed again at the top. A row is never split across two pages, so one that does not fit in the space left moves whole to the next page. A table with no items prints its heading row alone.

The Ruby drawing takes its look from keystone_ui. It reads the `--ks-` tokens for fonts, weights, text colours and spacing, and the text sizes, line heights, letter spacing, fills, borders, rounded corners, padding and alignment keystone_ui's heading, caption, paragraph, alert, value list, button, accordion and table rules use, from the stylesheet `KeystoneUi::Pages.pdf_stylesheet` names, in light mode. A label prints in capitals, as the caption does on screen. A button prints in the look of keystone_ui's primary button at its medium size. An alert prints on the fill and in the text colour its type is given, and a label and value list sets its total row apart at the strong weight. A table prints its heading, group and total rows on the table head fill at the table header's weight, its item rows on the table body fill divided by lines in the divider colour, the one pixel gray line keystone_ui's table draws under the heading row and above the total row, its cells centred from top to bottom in their row, and its edge in the table's border and rounded corners with the fills clipped to them, without the shadow the screen gives it. A default look the host names with `default_look` and a token the host's own stylesheet changes both reach the PDF.

A font named only by system fonts, with no font files, prints in Helvetica. A font the stylesheet loads with `@font-face` prints from TrueType copies of its files, since the PDF cannot read `.woff2` or `.woff`. Serve a `.ttf` copy beside each font file, under the same name, in the public folder or among the assets:

```
public/InterVariable.woff2
public/InterVariable.ttf
public/InterVariable-Italic.woff2
public/InterVariable-Italic.ttf
```

The PDF prints regular, bold and italic text from the copies whose `@font-face` rules give those weights and styles. Asking for a PDF in a font with no TrueType copy served raises a `PrintFailed` naming the font and the file it looked for.

### When a PDF cannot be made

A PDF that cannot be made raises `KeystoneUi::Pages::PrintFailed` with a message saying why. Under the Ruby drawing that is any of these:

- An element without a PDF drawing, named by its element.
- An element the catalog does not have, named by its key.
- Text holding a character its font cannot draw, named by its element and the character. Helvetica draws only the Windows-1252 characters, so a page using others needs a font served as TrueType copies that holds them.
- A keystone_ui token the stylesheet does not set, or sets to a colour or length the gem cannot read, named by its token.
- A font with no TrueType copy served, named by its font and the file it looked for.

A refused PDF keeps no file, so asking again after the page or the stylesheet is fixed makes a new one. An editor who clicks PDF in the page list is sent back to the list with the refusal's message shown. A page whose PDF is refused when it is published, or by `prepare_pdf`, is still published, and the refusal is reported through `Rails.error` with the page's id and name, since no one is waiting on that PDF to read it.

## Reporting views and clicks to the host

The gem keeps no record of who views a page or what they click. A host that wants to know registers a handler on the place, and the gem hands each view and click to it:

```ruby
KeystoneUi::Pages.register_place("marketing", label: "Marketing site", events: ->(event) { PageView.record(event) })
```

The handler receives a `KeystoneUi::Pages::Event` holding `page`, `place`, `kind` (`"view"` or `"click"`), `element` and `request`. For a click, `element` is the id of the page element the clicked link or button sits in, and for a view it is nil. Deciding what counts as a visit, honouring Do Not Track and leaving out crawlers is the handler's job.

The handler runs inside the event request, so it should enqueue anything slow, such as a call to another service, rather than do it there:

```ruby
events: ->(event) { PageEventJob.perform_later(event.page, event.kind, event.element) }
```

A handler that raises is reported through `Rails.error` with the page's id and the event's kind, and the browser gets the same answer as when it succeeds. A request that fails in the browser shows the visitor nothing.

The handler only receives events that describe the live page. An event of any kind other than a view or a click is refused, and so is a click whose element is missing or not on the live version. A page the browser prerenders sends its view only when the visitor opens it.

A page opened at its public address, or drawn with `keystone_ui_page` in a host view, sends its view from the visitor's browser once it loads. View live in the builder and a printed PDF send nothing. That only happens when the live version is drawn and the page's place has a handler. Drawing an older version by number, or a page from a place with no handler, sends nothing. The helper puts its script in `content_for :head`, so the host layout must call `yield :head` inside `<head>`. The same pages send a click on any link, button or card link, including one that opens another page, and a click anywhere else sends nothing. Views and clicks are sent without a form token and the gem sets no cookie.

### Sending views and clicks to a third-party tag

The same pages also fire two events on `document`, so an analytics tag set once in the host layout can send them on:

- `keystone-ui-pages:view`, whose `detail` holds `slug` and `place`.
- `keystone-ui-pages:click`, whose `detail` holds `slug`, `place`, `element` (the element id) and `href` (the link's full address, or null for a button).

They fire whether or not the event address accepts the view or click, and only on pages whose place has a handler, so a handler that does nothing turns them on. Add the listener in `<head>` before `yield :head`, so it is in place before the page's view fires:

```erb
<script>
  document.addEventListener("keystone-ui-pages:view", (event) => {
    gtag("event", "page_view", { page_slug: event.detail.slug, page_place: event.detail.place })
  })
  document.addEventListener("keystone-ui-pages:click", (event) => {
    gtag("event", "select_content", { page_slug: event.detail.slug, element_id: event.detail.element, link_url: event.detail.href })
  })
</script>
<%= yield :head %>
```

Plausible's `plausible("Page click", { props: event.detail })` or Meta's `fbq("trackCustom", "PageClick", event.detail)` go in the same listeners.

## Showing a host's sequence in the builder

A host that keeps pages in an order of its own, such as the pages of a funnel, names a method on its controller that answers a sequence by its key:

```ruby
KeystoneUi::Pages.register_place("funnel", label: "Funnel", listed: false, sequence_method: :funnel_sequence, adds_page_method: :add_funnel_page)
```

The gem calls the method on the editor's controller with the sequence's key. It answers a `KeystoneUi::Pages::Sequence` holding `title`, `pages` and `back_url`, or nil to refuse:

```ruby
def funnel_sequence(key)
  funnel = current_team.funnels.find_by(key: key)
  return unless funnel

  KeystoneUi::Pages::Sequence.new(title: funnel.name, pages: funnel.pages_in_order, back_url: funnel_path(funnel))
end
```

`pages` are the sequence's pages in the order a visitor goes through them. The gem keeps no order of its own, so the list shows the pages exactly as the method answers them. Each page in the list shows whether it is a draft, published or unpublished.

A sequence may also name `screen_url:`, the address of the host's own screen for the sequence, such as where the host shows its steps. The list then shows a Flow link to it:

```ruby
KeystoneUi::Pages::Sequence.new(title: funnel.name, pages: funnel.pages_in_order, back_url: funnel_path(funnel), screen_url: funnel_flow_path(funnel))
```

Staff open a sequence at `/pages/manage/sequences/<place>/<key>`. The builder shows the sequence's first page, with the sequence's title and its pages numbered from 1 beside it and the page being built marked. Choosing a page in the list opens it with the same list beside it. A sequence with no pages shows an empty page area saying no page has been added yet. The Back link goes to `back_url`, and a nil answer, or a place with no `sequence_method:`, gets the host's refusal.

A place with a `sequence_method:` also names an `adds_page_method:`, and a place that names one without the other fails the app's boot. The gem calls it on the editor's controller with the sequence's key, the new page and the page that was open when Add page was pressed, or nil when the sequence had no pages:

```ruby
def add_funnel_page(key, page, after)
  current_team.funnels.find_by!(key: key).add_page(page, after: after)
end
```

The Add page button in the sequence's list opens a form for the page's name, and a page left unnamed gets the place's `default_name:`. Its Start from list offers Blank page or a copy of any page in the same place that the current owner owns and is not archived, including pages of other sequences. A copy starts with that page's content and nothing else, as a draft, and the two pages change apart from then on. The gem makes the page in the sequence's place for the current owner, with the sequence's key, then calls the method and opens the new page on the sequence screen. The gem records no order, so the host decides where the page goes, and the list shows it wherever `sequence_method:` answers it. A sequence the host answers nil for refuses the form and adds no page.

To let staff decide when visitors see a changed sequence, name a `publishes_sequence_method:` when registering the place. The sequence's list then shows a Publish button, and pressing it calls the method on the editor's controller with the sequence's key. Adding a page never calls it. A sequence the host answers nil for refuses the button's request. To refuse with a reason, raise `KeystoneUi::Pages::SequencePublishRefused`, and any other error is left to the host's error handling:

```ruby
def publish_funnel(key)
  funnel = current_team.funnels.find_by!(key: key)
  raise KeystoneUi::Pages::SequencePublishRefused, "This funnel has no pages" if funnel.pages.empty?

  funnel.publish
end
```

Staff return to the sequence screen on the page they had open, and see a message that the sequence is published or the reason the host gave. This is separate from each page's own Publish button, which publishes that page's content.

To let staff remove a page from a sequence, name a `removes_page_method:` when registering the place. The sequence's list then shows Remove beside each page, which opens a confirmation screen. Confirming archives the page, so visitors can no longer open it, and calls the method on the editor's controller with the sequence's key and the page, inside one database transaction:

```ruby
def remove_funnel_page(key, page)
  current_team.funnels.find_by!(key: key).remove_page(page)
end
```

The method has to take the page out of what `sequence_method:` answers, since the gem keeps no order of its own. Staff return to the sequence screen on the page before the removed one, and a sequence whose first page was removed opens without naming a page, which shows its first remaining page or the empty page area. When the method raises, the page stays unarchived and the error goes to the host's error handling. A page the sequence does not answer, or a place with no `removes_page_method:`, gets the host's refusal.

Each page keeps a `sequence_key`, set when the page is made and refused if it is changed later. Pages made in the page list have none, and their builder is unchanged.

To lead visitors from one page to the next, name a `next_page_method:` when registering the place. The gem calls it on the controller drawing the page with the page being shown, so it can read the visitor's request, and it answers an address or nil:

```ruby
KeystoneUi::Pages.register_place("funnel", label: "Funnel", listed: false, sequence_method: :funnel_sequence, adds_page_method: :add_funnel_page, next_page_method: :funnel_next_page)

def funnel_next_page(page)
  funnels.page_after(page)&.then { |following| keystone_ui_pages.page_path(following.slug) }
end
```

The place then offers a Next page element, with a label staff can change. A visitor sees a button leading to the method's answer, asked for on each visit rather than cached with the page, and sees no button when it answers nil. A page printed to a PDF has no button. A form in the place also offers `next_page` under After submitting, which sends the visitor to the method's answer once the handler has received the submission, or shows the thank-you message when it answers nil. A place with no `next_page_method:` offers neither.

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
| A place leaves out an element | Open a Client portal page in the builder | No Form in the element list |
| A form reaches its place's handler | Add a Form to a Marketing site page, publish it, open it and submit the form | The thank-you message, and a `Form submission on` line in the server log |

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
