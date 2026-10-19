# frozen_string_literal: true

module KeystoneUi
  module Pages
    module Manage
      class AccessExceptionsController < BaseController
        include EditsPages

        def update
          if page.update(access_exception: params[:access_exception].presence)
            shown
          else
            render json: { error: page.errors.full_messages.to_sentence }, status: :unprocessable_entity
          end
        end
      end
    end
  end
end
