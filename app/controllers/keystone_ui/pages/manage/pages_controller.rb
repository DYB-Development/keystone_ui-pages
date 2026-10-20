# frozen_string_literal: true

require "keystone_ui/pages/printer"

module KeystoneUi
  module Pages
    module Manage
      class PagesController < BaseController
        def index
          @archived = params[:archived].present?
          @pages = owned_pages.public_send(@archived ? :archived : :current).order(:name)
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

        def edit
          @page = owned_pages.find(params[:id])
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

        def archive
          owned_pages.find(params[:id]).archive
          redirect_to manage_pages_path
        end

        def restore
          owned_pages.find(params[:id]).restore
          redirect_to manage_pages_path
        end

        private

        def local_address?(address)
          address.to_s.match?(%r{\A/(?![/\\])})
        end
      end
    end
  end
end
