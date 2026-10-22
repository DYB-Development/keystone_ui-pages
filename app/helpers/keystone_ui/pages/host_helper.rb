# frozen_string_literal: true

module KeystoneUi
  module Pages
    module HostHelper
      include KeystoneUiHelper
      include DrawingHelper

      def keystone_ui_page(page, values: {}, version: nil)
        version = version ? page.versions.find_by(number: version) : page.live_version
        return if version.nil?

        reported = version == page.live_version && KeystoneUi::Pages.reported?(page.place)
        content_for :head, javascript_include_tag("keystone_ui_pages/reporting", defer: true) if reported
        tag.div(drawn_version(version, values: values), class: "@container", data: reported ? { page_events: keystone_ui_pages.page_events_path(page.slug), page_slug: page.slug, page_place: page.place } : {})
      end
    end
  end
end
