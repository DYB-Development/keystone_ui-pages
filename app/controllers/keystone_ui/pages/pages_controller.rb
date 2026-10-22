# frozen_string_literal: true

module KeystoneUi
  module Pages
    class PagesController < KeystoneUi::Pages.base_controller.constantize
      include HostChecks
      helper KeystoneUiHelper
      helper DrawingHelper
      layout -> { KeystoneUi::Pages.layout }

      def show
        page = owned_pages.find_by(slug: params[:slug])
        @version = page&.live_version
        return refuse if @version.nil? || !KeystoneUi::Pages.slugged?(page.place) || !viewable?(page)

        @values = visitor_values(page)
      end

      private

      def visitor_values(page)
        send(KeystoneUi::Pages.values_method, page) if KeystoneUi::Pages.values_method
      end
    end
  end
end
