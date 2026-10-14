# frozen_string_literal: true

module KeystoneUi
  module Pages
    module Manage
      class RowsController < BaseController
        include EditsPages

        def create
          changed(Operations.add_row(page.document, section_id: params.require(:section_id)))
        end
      end
    end
  end
end
