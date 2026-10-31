# frozen_string_literal: true

module KeystoneUi
  module Pages
    module Manage
      class SequencePagesController < BaseController
        def create
          page = Page.create!(params.require(:page).permit(:name).merge(place: params[:place], sequence_key: params[:key], owner: page_owner))
          send(KeystoneUi::Pages.place_settings.dig(params[:place], :adds_page_method), params[:key], page, open_page)
          head :created
        end

        private

        def open_page
          sequence(params[:place], params[:key]).pages.find { |page| page.id.to_s == params[:after_id].to_s }
        end
      end
    end
  end
end
