# frozen_string_literal: true

module KeystoneUi
  module Pages
    module Manage
      class NodesController < BaseController
        include EditsPages

        def update
          changed(Operations.arrange(page.document, node_id: params[:id], setting: params.require(:setting), value: params.require(:value)))
        end
      end
    end
  end
end
