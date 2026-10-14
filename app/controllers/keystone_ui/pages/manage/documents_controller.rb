# frozen_string_literal: true

module KeystoneUi
  module Pages
    module Manage
      class DocumentsController < BaseController
        include EditsPages

        def update
          changed(Operations.check(params.require(:document).to_unsafe_h.to_h))
        end
      end
    end
  end
end
