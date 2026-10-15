# frozen_string_literal: true

module KeystoneUi
  module Pages
    module Manage
      class NodesController < BaseController
        include EditsPages

        def update
          changed(Operations.arrange(page.document, node_id: params[:id], setting: params.require(:setting), value: params.require(:value)))
        end

        def move
          changed(Operations.move(page.document, node_id: params[:id], into: params[:into].presence, position: params.require(:position)))
        end

        def duplicate
          changed(Operations.duplicate(page.document, node_id: params[:id]))
        end

        def destroy
          changed(Operations.remove(page.document, node_id: params[:id]))
        end
      end
    end
  end
end
