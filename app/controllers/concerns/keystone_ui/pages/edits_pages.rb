# frozen_string_literal: true

require "keystone_ui/pages/operations"

module KeystoneUi
  module Pages
    module EditsPages
      extend ActiveSupport::Concern

      included do
        rescue_from InvalidDocument do |refusal|
          render json: { error: refusal.message }, status: :unprocessable_entity
        end
      end

      private

      def page
        @page ||= owned_pages.find(params[:page_id])
      end

      def changed(document)
        page.update!(document: document)
        render json: { canvas: helpers.editor_canvas(page), document: page.document }
      end
    end
  end
end
