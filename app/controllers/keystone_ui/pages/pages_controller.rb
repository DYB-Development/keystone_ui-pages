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
        refuse if @version.nil? || !viewable?(page)
      end

      private

      def viewable?(page)
        return true unless KeystoneUi::Pages.view_check_method

        send(KeystoneUi::Pages.view_check_method, page)
      end
    end
  end
end
