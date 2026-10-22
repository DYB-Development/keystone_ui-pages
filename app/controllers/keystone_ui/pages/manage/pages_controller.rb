# frozen_string_literal: true

require "keystone_ui/pages/printer"

module KeystoneUi
  module Pages
    module Manage
      class PagesController < BaseController
        def index
          @archived = params[:archived].present?
          @place = chosen_place
          @pages = owned_pages.public_send(@archived ? :archived : :current).order(:name)
          @pages = @pages.where(place: @place) if @place
          @printable = Printer.chrome.present?
        end

        def new
          @place = chosen_place
        end

        def create
          page = Page.new(params.require(:page).permit(:name, :slug, :place).merge(owner: page_owner))
          return render(:new, status: :unprocessable_entity) unless page.save

          redirect_to manage_page_path(page)
        end

        def show
          @page = owned_pages.find(params[:id])
          (session[:keystone_ui_pages_return_to] ||= {})[@page.id.to_s] = params[:return_to] if local_address?(params[:return_to])
        end

        def edit
          @page = owned_pages.find(params[:id])
        end

        def update
          @page = owned_pages.find(params[:id])
          return render(:edit, status: :unprocessable_entity) unless @page.update(params.require(:page).permit(:name, :slug, :place))

          redirect_to manage_pages_path(place: @page.place)
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

        def chosen_place
          params[:place] if KeystoneUi::Pages.places.key?(params[:place])
        end

        def local_address?(address)
          address.to_s.match?(%r{\A/(?![/\\])})
        end
      end
    end
  end
end
