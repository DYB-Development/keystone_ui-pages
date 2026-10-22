# frozen_string_literal: true

require "keystone_ui/pages/event"
require "keystone_ui/pages/operations"

module KeystoneUi
  module Pages
    class EventsController < KeystoneUi::Pages.base_controller.constantize
      include HostChecks
      skip_forgery_protection

      def create
        page = owned_pages.find_by(slug: params[:slug])
        return refuse unless page&.reporting? && viewable?(page) && described?(page)

        Rails.error.handle(context: { page_id: page.id, kind: kind }) do
          KeystoneUi::Pages.place_settings.dig(page.place, :events).call(Event.new(page: page, place: page.place, kind: kind, element: element, request: request))
        end
        head :no_content
      end

      private

      def described?(page)
        kind == "view" || (kind == "click" && on_live_version?(page))
      end

      def on_live_version?(page)
        Operations.elements(page.live_version.document).any? { |placed| placed["id"] == element }
      end

      def kind
        params.fetch(:kind, "view")
      end

      def element
        params[:element].presence if kind == "click"
      end
    end
  end
end
