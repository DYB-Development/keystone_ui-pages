# frozen_string_literal: true

module KeystoneUi
  module Pages
    module KeystoneElements
      module_function

      def register(catalog)
          catalog.register(key: :button, name: "Button", component: :ui_button,
            fields: [ { key: :label, label: "Label" }, { key: :href, label: "Address" } ])
          catalog.register(key: :progress, name: "Progress", component: :ui_progress,
            fields: [ { key: :value, label: "Value", kind: :number }, { key: :max, label: "Out of", kind: :number }, { key: :label, label: "Label", kind: :text } ])
          catalog.register(key: :alert, name: "Alert", component: :ui_alert,
            fields: [ { key: :message, label: "Message", kind: :long_text }, { key: :title, label: "Title", kind: :text },
                      { key: :type, label: "Type", kind: :one_of, options: %w[info success warning error], default: "info" },
                      { key: :dismissible, label: "Can be dismissed", kind: :yes_or_no } ])
          catalog.register(key: :code, name: "Code", component: :ui_code, body: :code,
            fields: [ { key: :code, label: "Code", kind: :long_text }, { key: :language, label: "Language", kind: :text },
                      { key: :caption, label: "Caption", kind: :text } ])
          catalog.register(key: :hero, name: "Hero", component: :ui_hero,
            fields: [ { key: :title, label: "Title", kind: :text, default: "Headline" },
                      { key: :subtitle, label: "Subtitle", kind: :long_text },
                      { key: :badge, label: "Badge", kind: :text },
                      { key: :layout, label: "Layout", kind: :one_of, options: %w[split centered], default: "split" } ])
          catalog.register(key: :cta_banner, name: "Call to action", component: :ui_cta_banner, body: :text,
            fields: [ { key: :title, label: "Title", kind: :text, default: "Ready to start?" },
                      { key: :subtitle, label: "Subtitle", kind: :text },
                      { key: :text, label: "Text", kind: :long_text } ])
          catalog.register(key: :card, name: "Card", component: :ui_card,
            fields: [ { key: :title, label: "Title", kind: :text, default: "Card title" },
                      { key: :summary, label: "Summary", kind: :long_text },
                      { key: :link, label: "Link", kind: :address },
                      { key: :cta, label: "Link text", kind: :text, default: "Read more" } ])
          catalog.register(key: :stat_card, name: "Stat", component: :ui_stat_card,
            fields: [ { key: :label, label: "Label", kind: :text, default: "Label" },
                      { key: :value, label: "Value", kind: :text, default: "0" },
                      { key: :suffix, label: "Suffix", kind: :text },
                      { key: :variant, label: "Tone", kind: :one_of, options: %w[neutral success danger warning info], default: "neutral" } ])
          catalog.register(key: :figure, name: "Figure", component: :ui_figure,
            fields: [ { key: :text, label: "Text", kind: :text, default: "0" },
                      { key: :tone, label: "Tone", kind: :one_of, options: %w[neutral success danger], default: "neutral" } ])
          catalog.register(key: :info, name: "Info", component: :ui_info, body: :detail,
            fields: [ { key: :summary, label: "Summary", kind: :text, default: "More information" },
                      { key: :detail, label: "Detail", kind: :long_text } ])
          catalog.register(key: :badge, name: "Badge", component: :ui_badge,
            fields: [ { key: :label, label: "Label", kind: :text, default: "Badge" },
                      { key: :variant, label: "Tone", kind: :one_of, options: %w[neutral success danger warning info], default: "neutral" } ])
          catalog.register(key: :copy_button, name: "Copy button", component: :ui_copy_button,
            fields: [ { key: :text, label: "Text to copy", kind: :text },
                      { key: :label, label: "Label", kind: :text, default: "Copy" } ])
      end
    end
  end
end
