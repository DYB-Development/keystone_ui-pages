# frozen_string_literal: true

module KeystoneUi
  module Pages
    module Manage
      class AccessExceptionsController < BaseController
        include EditsPages

        def update
          page.update!(access_exception: params[:access_exception])
          head :no_content
        end
      end
    end
  end
end
