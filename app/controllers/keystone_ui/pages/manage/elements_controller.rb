# frozen_string_literal: true

module KeystoneUi
  module Pages
    module Manage
      class ElementsController < BaseController
        include EditsPages

        def create
          changed(Operations.add(page.document, params.require(:key), column_id: params.require(:column_id)))
        end

        def bind
          changed(Operations.bind(page.document, element_id: params[:id], field: params.require(:field), name: params.require(:name), fallback: params[:fallback].presence))
        end

        def update
          changed(Operations.set(page.document, element_id: params[:id], field: params.require(:field), value: field_value))
        end

        private

        def field_value
          value = params.to_unsafe_h["value"]
          return value.map { |entry| entry.to_h.stringify_keys } if value.is_a?(Array)
          return { "html" => value["html"].to_s } if value.is_a?(Hash) && value.key?("html")

          value.to_s
        end
      end
    end
  end
end
