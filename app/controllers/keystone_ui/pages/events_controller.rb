# frozen_string_literal: true

require "keystone_ui/pages/event"

module KeystoneUi
  module Pages
    class EventsController < KeystoneUi::Pages.base_controller.constantize
      include HostChecks
      skip_forgery_protection

      def create
        page = owned_pages.find_by(slug: params[:slug])
        return refuse unless page&.live_version && KeystoneUi::Pages.reported?(page.place) && viewable?(page)

        KeystoneUi::Pages.place_settings.dig(page.place, :events).call(Event.new(page: page, place: page.place, kind: kind, element: element, request: request))
        head :no_content
      end

      private

      def kind
        params[:kind] == "click" ? "click" : "view"
      end

      def element
        params[:element].presence if kind == "click"
      end
    end
  end
end
