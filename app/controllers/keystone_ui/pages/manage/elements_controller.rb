# frozen_string_literal: true

require "keystone_ui/pages/operations"

module KeystoneUi
  module Pages
    module Manage
      class ElementsController < BaseController
        def create
          page = owned_pages.find(params[:page_id])
          page.update!(document: Operations.add(page.document, params.require(:key), column_id: params.require(:column_id)))
          render json: { canvas: helpers.drawn_document(page.document, editing: true), document: page.document }
        end
      end
    end
  end
end
