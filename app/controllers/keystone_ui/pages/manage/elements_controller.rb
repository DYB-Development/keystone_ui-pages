# frozen_string_literal: true

module KeystoneUi
  module Pages
    module Manage
      class ElementsController < BaseController
        include EditsPages

        def create
          changed(Operations.add(page.document, params.require(:key), column_id: params.require(:column_id)))
        end

        def update
          changed(Operations.set(page.document, element_id: params[:id], field: params.require(:field), value: params[:value].to_s))
        end
      end
    end
  end
end
