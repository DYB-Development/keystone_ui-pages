# frozen_string_literal: true

module KeystoneUi
  module Pages
    class ViewsController < KeystoneUi::Pages.base_controller.constantize
      include HostChecks

      def create
        PageCount.add(owned_pages.find_by(slug: params[:slug]), "view")
        head :no_content
      end
    end
  end
end
