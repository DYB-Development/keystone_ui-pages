# frozen_string_literal: true

module KeystoneUi
  module Pages
    module Manage
      class SequencePagesController < BaseController
        def create
          Page.create!(params.require(:page).permit(:name).merge(place: params[:place], sequence_key: params[:key], owner: page_owner))
          head :created
        end
      end
    end
  end
end
