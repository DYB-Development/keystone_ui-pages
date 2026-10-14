# frozen_string_literal: true

module KeystoneUi
  module Pages
    module Manage
      class SectionsController < BaseController
        include EditsPages

        def create
          changed(Operations.add_section(page.document))
        end
      end
    end
  end
end
