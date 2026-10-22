# frozen_string_literal: true

module KeystoneUi
  module Pages
    module HostHelper
      include KeystoneUiHelper
      include DrawingHelper

      def keystone_ui_page(page, values: {}, version: nil)
        version = version ? page.versions.find_by(number: version) : page.live_version
        return if version.nil?

        tag.div(drawn_version(version, values: values), class: "@container", data: version == page.live_version ? reporting_data(page) : {})
      end
    end
  end
end
