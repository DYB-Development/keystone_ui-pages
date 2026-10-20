# frozen_string_literal: true

module KeystoneUi
  module Pages
    module Manage
      class TitlesController < BaseController
        include EditsPages

        def update
          changed(Operations.title(page.document, params[:title]))
        end
      end
    end
  end
end
