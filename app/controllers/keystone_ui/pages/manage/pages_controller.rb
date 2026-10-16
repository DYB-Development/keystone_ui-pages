# frozen_string_literal: true

module KeystoneUi
  module Pages
    module Manage
      class PagesController < BaseController
        def index
          @pages = owned_pages.order(:name)
        end

        def new
        end

        def create
          page = Page.create!(params.require(:page).permit(:name, :slug).merge(owner: page_owner))
          redirect_to manage_page_path(page)
        end

        def show
          @page = owned_pages.find(params[:id])
        end

        def publish
          page = owned_pages.find(params[:id])
          page.publish
          redirect_to manage_page_path(page)
        end
      end
    end
  end
end
