# frozen_string_literal: true

module KeystoneUi
  module Pages
    class ViewsController < KeystoneUi::Pages.base_controller.constantize
      include HostChecks

      def create
        page = owned_pages.find_by(slug: params[:slug])
        return refuse unless page&.live_version && KeystoneUi::Pages.counted?(page.place)

        PageCount.add(page, "view")
        head :no_content
      end
    end
  end
end
