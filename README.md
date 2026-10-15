# keystone_ui-pages
A flow-layout page builder that draws keystone_ui elements from a versioned JSON page document

## Elements

The catalog offers these keystone_ui components as page elements by default: `button`, `progress`, `alert`, `code`, `heading`, `label` (drawn by `ui_caption`), `paragraph`, `hero`, `cta_banner`, `card`, `stat_card`, `figure`, `info`, `badge`, `copy_button`, `feature_grid`, `accordion`, `data_table` and `line_chart`.

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
