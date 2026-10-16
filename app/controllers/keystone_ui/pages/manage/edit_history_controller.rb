# frozen_string_literal: true

module KeystoneUi
  module Pages
    module Manage
      class EditHistoryController < BaseController
        include EditsPages

        def undo
          page.undo
          shown
        end

        def redo
          page.redo
          shown
        end
      end
    end
  end
end
