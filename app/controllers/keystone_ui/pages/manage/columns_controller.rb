# frozen_string_literal: true

module KeystoneUi
  module Pages
    module Manage
      class ColumnsController < BaseController
        include EditsPages

        def create
          changed(Operations.add_column(page.document, row_id: params.require(:row_id)))
        end
      end
    end
  end
end
