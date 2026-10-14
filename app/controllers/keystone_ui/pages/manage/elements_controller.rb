# frozen_string_literal: true

require "keystone_ui/pages/operations"

module KeystoneUi
  module Pages
    module Manage
      class ElementsController < BaseController
        def create
          changed(Operations.add(page.document, params.require(:key), column_id: params.require(:column_id)))
        end

        def update
          changed(Operations.set(page.document, element_id: params[:id], field: params.require(:field), value: params[:value].to_s))
        end

        private

        def page
          @page ||= owned_pages.find(params[:page_id])
        end

        def changed(document)
          page.update!(document: document)
          render json: { canvas: helpers.drawn_document(page.document, editing: true), document: page.document }
        end
      end
    end
  end
end
