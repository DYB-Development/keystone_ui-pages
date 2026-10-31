# frozen_string_literal: true

require "keystone_ui/pages/operations"

module KeystoneUi
  module Pages
    module EditorHelper
      def editor_props(page)
        {
          elements: KeystoneUi::Pages.offered_elements(page.place).map { |element| element.to_h.slice(:key, :name, :fields, :icon, :group, :align) },
          canvas: editor_canvas(page),
          document: page.document,
          elements_url: manage_page_elements_path(page),
          sections_url: manage_page_sections_path(page),
          columns_url: manage_page_columns_path(page),
          rows_url: manage_page_rows_path(page),
          nodes_url: "#{manage_page_path(page)}/nodes",
          arrangements: Operations::ARRANGEMENTS,
          defaults: Operations::DEFAULTS,
          shares: Operations::SHARES,
          value_names: Values.names,
          looks: KeystoneUi.configuration.looks.keys,
          samples: Values.samples_for(page),
          sample: chosen_sample(page),
          samples_url: manage_page_sample_path(page),
          title_url: manage_page_title_path(page),
          access_exceptions: KeystoneUi::Pages.access_exceptions.invert.to_a,
          access_exception: page.access_exception,
          access_exception_url: manage_page_access_exception_path(page),
          history_url: manage_page_versions_path(page),
          undo_url: manage_page_undo_path(page),
          redo_url: manage_page_redo_path(page),
          undoable: page.undo_history.any?,
          redoable: page.undone_changes.any?,
          back_url: session.dig(:keystone_ui_pages_return_to, page.id.to_s) || manage_pages_path(place: page.place),
          live_url: (manage_page_live_path(page) if page.live_version),
          token: form_authenticity_token
        }
      end

      def sequence_props(sequence, built)
        { title: sequence.title, pages: sequence.pages.map { |page| { id: page.id, name: page.name, current: page == built } } }
      end

      def editor_canvas(page)
        drawn_document(page.document, editing: true, values: Values.sample(page, chosen_sample(page)))
      end

      def chosen_sample(page)
        session.dig(:keystone_ui_pages_samples, page.id.to_s) || Values.samples_for(page).first&.last
      end
    end
  end
end
