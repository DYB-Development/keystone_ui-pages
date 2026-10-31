# frozen_string_literal: true

module KeystoneUi
  module Pages
    module Manage
      class SequencePagesController < BaseController
        before_action :find_sequence

        def new
          @default_name = Page.new(place: params[:place], owner: page_owner).default_name
        end

        def create
          open_page = @sequence.pages.find { |page| page.id.to_s == params[:after_id].to_s }
          page = Page.create!(params.require(:page).permit(:name).merge(place: params[:place], sequence_key: params[:key], owner: page_owner))
          send(KeystoneUi::Pages.place_settings.dig(params[:place], :adds_page_method), params[:key], page, open_page)
          redirect_to manage_sequence_path(params[:place], params[:key], page_id: page.id)
        end

        private

        def find_sequence
          @sequence = sequence(params[:place], params[:key])
          refuse unless @sequence
        end
      end
    end
  end
end
