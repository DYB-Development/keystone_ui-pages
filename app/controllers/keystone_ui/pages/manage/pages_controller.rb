# frozen_string_literal: true

require "keystone_ui/pages/printer"

module KeystoneUi
  module Pages
    module Manage
      class PagesController < BaseController
        def index
          @pages = owned_pages.order(:name)
          @printable = Printer.chrome.present?
        end

        def new
        end

        def create
          page = Page.create!(params.require(:page).permit(:name, :slug, :place).merge(owner: page_owner))
          redirect_to manage_page_path(page)
        end

        def show
          @page = owned_pages.find(params[:id])
          (session[:keystone_ui_pages_return_to] ||= {})[@page.id.to_s] = params[:return_to] if local_address?(params[:return_to])
        end

        def publish
          page = owned_pages.find(params[:id])
          page.publish
          redirect_to manage_page_path(page)
        end

        def unpublish
          page = owned_pages.find(params[:id])
          page.unpublish
          redirect_to manage_page_path(page)
        end

        private

        def local_address?(address)
          address.to_s.match?(%r{\A/(?![/\\])})
        end
      end
    end
  end
end
