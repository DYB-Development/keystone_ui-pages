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
          @pages = @place ? @pages.where(place: @place) : @pages.where.not(place: KeystoneUi::Pages.unlisted_places).or(@pages.where(place: nil))
          @printable = Printer.chrome.present?
        end

        def new
          @place = chosen_place
          return refuse if KeystoneUi::Pages.unlisted_places.include?(@place)

          @default_name = Page.new(place: @place, owner: page_owner).default_name
        end

        def create
          page = Page.new(params.require(:page).permit(:name, :slug, :place).merge(owner: page_owner))
          return refuse if KeystoneUi::Pages.unlisted_places.include?(page.place)

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
          redirect_to local_address?(params[:return_to]) ? params[:return_to] : manage_page_path(page)
        end

        def unpublish
          page = owned_pages.find(params[:id])
          page.unpublish
          redirect_to local_address?(params[:return_to]) ? params[:return_to] : manage_page_path(page)
        end

        def archive
          page = owned_pages.find(params[:id])
          page.archive
          redirect_to manage_pages_path(place: page.place)
        end

        def restore
          page = owned_pages.find(params[:id])
          page.restore
          redirect_to manage_pages_path(place: page.place)
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
