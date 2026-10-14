# frozen_string_literal: true

module KeystoneUi
  module Pages
    module Manage
      class BaseController < KeystoneUi::Pages.base_controller.constantize
        include HostChecks
        helper KeystoneUiHelper
        helper DrawingHelper
        helper EditorHelper
        helper KeystoneUi::React::MountHelper
        layout -> { KeystoneUi::Pages.editor_layout }

        before_action :refuse_unless_editor

        private

        def refuse_unless_editor
          refuse unless editor?
        end

        def editor?
          KeystoneUi::Pages.edit_check_method.nil? || send(KeystoneUi::Pages.edit_check_method)
        end
      end
    end
  end
end
