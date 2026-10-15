# frozen_string_literal: true

module KeystoneUi
  module Pages
    module Manage
      class VersionsController < BaseController
        def index
          @page = owned_pages.find(params[:page_id])
          @versions = @page.versions.reorder(number: :desc)
        end

        def show
          @page = owned_pages.find(params[:page_id])
          @version = @page.versions.find(params[:id])
        end
      end
    end
  end
end
