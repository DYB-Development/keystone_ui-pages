# frozen_string_literal: true

require "keystone_ui/pages/event"

module KeystoneUi
  module Pages
    class EventsController < KeystoneUi::Pages.base_controller.constantize
      include HostChecks

      def create
        page = owned_pages.find_by(slug: params[:slug])
        KeystoneUi::Pages.place_settings.dig(page.place, :events).call(Event.new(page: page, place: page.place, kind: "view", element: nil, request: request))
        head :no_content
      end
    end
  end
end
