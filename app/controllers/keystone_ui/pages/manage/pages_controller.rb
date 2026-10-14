# frozen_string_literal: true

module KeystoneUi
  module Pages
    module Manage
      class PagesController < KeystoneUi::Pages.base_controller.constantize
        include HostChecks
        helper KeystoneUiHelper
        helper DrawingHelper
        layout -> { KeystoneUi::Pages.editor_layout }

        def new
        end

        def create
          page = Page.create!(params.require(:page).permit(:name, :slug).merge(owner: page_owner))
          redirect_to manage_page_path(page)
        end

        def show
          @page = owned_pages.find(params[:id])
        end
      end
    end
  end
end
