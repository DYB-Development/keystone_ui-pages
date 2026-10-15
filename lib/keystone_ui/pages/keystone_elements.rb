# frozen_string_literal: true

module KeystoneUi
  module Pages
    module KeystoneElements
      module_function

      def register(catalog)
        catalog.register(key: :button, name: "Button", component: :ui_button, icon: :cursor, group: "Basics", align: "start",
          fields: [ { key: :label, label: "Label", default: "Button" }, { key: :href, label: "Address" } ])
        catalog.register(key: :progress, name: "Progress", component: :ui_progress, icon: :progress, group: "Data",
          fields: [ { key: :value, label: "Value", kind: :number, default: "0" }, { key: :max, label: "Out of", kind: :number, default: "100" }, { key: :label, label: "Label", kind: :text, default: "Progress" } ])
        catalog.register(key: :alert, name: "Alert", component: :ui_alert, icon: :alert, group: "Text",
          fields: [ { key: :message, label: "Message", kind: :long_text, default: "Something worth knowing." }, { key: :title, label: "Title", kind: :text },
                    { key: :type, label: "Type", kind: :one_of, options: %w[info success warning error], default: "info" },
                    { key: :dismissible, label: "Can be dismissed", kind: :yes_or_no } ])
        catalog.register(key: :code, name: "Code", component: :ui_code, icon: :code, group: "Text", body: :code,
          fields: [ { key: :code, label: "Code", kind: :long_text, default: "puts \"Hello\"" }, { key: :language, label: "Language", kind: :text },
                    { key: :caption, label: "Caption", kind: :text } ])
        catalog.register(key: :heading, name: "Heading", component: :ui_heading, icon: :heading, group: "Text",
          fields: [ { key: :text, label: "Text", kind: :text, default: "Heading" },
                    { key: :size, label: "Size", kind: :one_of, options: %w[sm md lg], default: "md" },
                    { key: :note, label: "Note", kind: :text } ])
        catalog.register(key: :label, name: "Label", component: :ui_caption, icon: :tag, group: "Text",
          fields: [ { key: :text, label: "Text", kind: :text, default: "Label" } ])
        catalog.register(key: :paragraph, name: "Paragraph", component: :ui_paragraph, icon: :text, group: "Text",
          fields: [ { key: :text, label: "Text", kind: :long_text, default: "Write the text of this paragraph here." } ])
        catalog.register(key: :hero, name: "Hero", component: :ui_hero, icon: :heading, group: "Text",
          fields: [ { key: :title, label: "Title", kind: :text, default: "Headline" },
                    { key: :subtitle, label: "Subtitle", kind: :long_text },
                    { key: :badge, label: "Badge", kind: :text },
                    { key: :layout, label: "Layout", kind: :one_of, options: %w[split centered], default: "split" },
                    { key: :height, label: "Height", kind: :one_of, options: %w[content tall full_screen], default: "tall",
                      classes: { "content" => "[&_.ks-hero]:min-h-0", "tall" => "[&_.ks-hero]:min-h-[28rem]", "full_screen" => "[&_.ks-hero]:min-h-screen" } } ])
        catalog.register(key: :cta_banner, name: "Call to action", component: :ui_cta_banner, icon: :megaphone, group: "Content", body: :text,
          fields: [ { key: :title, label: "Title", kind: :text, default: "Ready to start?" },
                    { key: :subtitle, label: "Subtitle", kind: :text },
                    { key: :text, label: "Text", kind: :long_text } ])
        catalog.register(key: :card, name: "Card", component: :ui_card, icon: :card, group: "Content",
          fields: [ { key: :title, label: "Title", kind: :text, default: "Card title" },
                    { key: :summary, label: "Summary", kind: :long_text },
                    { key: :link, label: "Link", kind: :address, default: "#" },
                    { key: :cta, label: "Link text", kind: :text, default: "Read more" } ])
        catalog.register(key: :stat_card, name: "Stat", component: :ui_stat_card, icon: :chart, group: "Data",
          fields: [ { key: :label, label: "Label", kind: :text, default: "Label" },
                    { key: :value, label: "Value", kind: :text, default: "0" },
                    { key: :suffix, label: "Suffix", kind: :text },
                    { key: :variant, label: "Tone", kind: :one_of, options: %w[neutral success danger warning info], default: "neutral" } ])
        catalog.register(key: :figure, name: "Figure", component: :ui_figure, icon: :number, group: "Data",
          fields: [ { key: :text, label: "Text", kind: :text, default: "0" },
                    { key: :tone, label: "Tone", kind: :one_of, options: %w[neutral success danger], default: "neutral" } ])
        catalog.register(key: :info, name: "Info", component: :ui_info, icon: :info, group: "Text", body: :detail,
          fields: [ { key: :summary, label: "Summary", kind: :text, default: "More information" },
                    { key: :detail, label: "Detail", kind: :long_text } ])
        catalog.register(key: :badge, name: "Badge", component: :ui_badge, icon: :tag, group: "Basics", align: "start",
          fields: [ { key: :label, label: "Label", kind: :text, default: "Badge" },
                    { key: :variant, label: "Tone", kind: :one_of, options: %w[neutral success danger warning info], default: "neutral" } ])
        catalog.register(key: :copy_button, name: "Copy button", component: :ui_copy_button, icon: :copy, group: "Basics", align: "start",
          fields: [ { key: :text, label: "Text to copy", kind: :text },
                    { key: :label, label: "Label", kind: :text, default: "Copy" } ])
        catalog.register(key: :feature_grid, name: "Feature grid", component: :ui_feature_grid, icon: :card, group: "Content",
          fields: [ { key: :title, label: "Title", kind: :text, default: "Why teams choose us" },
                    { key: :subtitle, label: "Subtitle", kind: :text },
                    { key: :features, label: "Features", kind: :list,
                      entry: [ { key: :title, label: "Title", kind: :text }, { key: :description, label: "Description", kind: :long_text },
                               { key: :icon, label: "Icon", kind: :text, hidden: true,
                                 default: '<svg viewBox="0 0 24 24" class="size-6 fill-none stroke-current stroke-2"><path d="M5 12l5 5L20 7"/></svg>' } ],
                      default: [ { "title" => "Fast", "description" => "Pages load quickly." },
                                 { "title" => "Clear", "description" => "Every page reads plainly." },
                                 { "title" => "Yours", "description" => "Built from your own components." } ] } ])
        catalog.register(key: :accordion, name: "Accordion", component: :ui_accordion, icon: :code, group: "Text",
          fields: [ { key: :items, label: "Questions", kind: :list,
                      entry: [ { key: :question, label: "Question", kind: :text }, { key: :answer, label: "Answer", kind: :long_text } ],
                      default: [ { "question" => "What is this?", "answer" => "A question visitors often ask." },
                                 { "question" => "How does it work?", "answer" => "The answer opens below its question." } ] } ])
        catalog.register(key: :data_table, name: "Table", component: :ui_data_table, icon: :card, group: "Data",
          fields: [ { key: :items, label: "Rows", kind: :data,
                      default: [ { "name" => "First row", "status" => "Open" }, { "name" => "Second row", "status" => "Closed" } ] },
                    { key: :columns, label: "Columns", kind: :list, as: :pairs,
                      entry: [ { key: :key, label: "Key", kind: :text }, { key: :label, label: "Heading", kind: :text } ],
                      default: [ { "key" => "name", "label" => "Name" }, { "key" => "status", "label" => "Status" } ] } ])
        catalog.register(key: :line_chart, name: "Line chart", component: :ui_line_chart, icon: :chart, group: "Data",
          fields: [ { key: :series, label: "Series", kind: :data, default: [ { "name" => "Visits", "data" => [ 3, 5, 4, 7 ] } ] },
                    { key: :labels, label: "Labels", kind: :data, default: %w[Mon Tue Wed Thu] } ])
      end
    end
  end
end
