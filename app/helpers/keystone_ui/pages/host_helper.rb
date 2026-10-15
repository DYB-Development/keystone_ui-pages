# frozen_string_literal: true

module KeystoneUi
  module Pages
    module HostHelper
      include KeystoneUiHelper
      include DrawingHelper

      def keystone_ui_page(page, values: {})
        version = page.live_version
        return if version.nil?

        tag.div(drawn_document(version.document, values: values), class: "@container")
      end
    end
  end
end
