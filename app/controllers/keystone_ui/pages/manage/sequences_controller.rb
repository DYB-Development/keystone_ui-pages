# frozen_string_literal: true

module KeystoneUi
  module Pages
    module Manage
      class SequencesController < BaseController
        def show
          @sequence = sequence(params[:place], params[:key])
          return refuse unless @sequence

          @page = @sequence.pages.first
        end
      end
    end
  end
end
