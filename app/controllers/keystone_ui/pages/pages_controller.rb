# frozen_string_literal: true

module KeystoneUi
  module Pages
    class PagesController < KeystoneUi::Pages.base_controller.constantize
      helper KeystoneUiHelper
      helper DrawingHelper
      layout -> { KeystoneUi::Pages.layout }

      def show
        @version = Page.find_by!(slug: params[:slug]).live_version
      end
    end
  end
end
