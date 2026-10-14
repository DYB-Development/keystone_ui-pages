# frozen_string_literal: true

module KeystoneUi
  module Pages
    class PagesController < KeystoneUi::Pages.base_controller.constantize
      helper KeystoneUiHelper
      helper DrawingHelper
      layout -> { KeystoneUi::Pages.layout }

      def show
        @version = owned_pages.find_by(slug: params[:slug])&.live_version
        refuse if @version.nil?
      end

      private

      def owned_pages
        return Page.all unless KeystoneUi::Pages.owner_method

        Page.where(owner: send(KeystoneUi::Pages.owner_method))
      end

      def refuse
        return head(:not_found) unless KeystoneUi::Pages.refusal_method

        send(KeystoneUi::Pages.refusal_method)
      end
    end
  end
end
