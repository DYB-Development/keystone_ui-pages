# frozen_string_literal: true

module KeystoneUi
  module Pages
    module Manage
      class SequencesController < BaseController
        def show
          @sequence = sequence(params[:place], params[:key])
          return refuse unless @sequence

          @page = params[:page_id] ? @sequence.pages.find { |page| page.id.to_s == params[:page_id] } : @sequence.pages.first
        end
      end
    end
  end
end
