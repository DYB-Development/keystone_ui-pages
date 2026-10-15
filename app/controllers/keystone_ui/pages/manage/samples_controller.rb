# frozen_string_literal: true

module KeystoneUi
  module Pages
    module Manage
      class SamplesController < BaseController
        include EditsPages

        def update
          (session[:keystone_ui_pages_samples] ||= {})[page.id.to_s] = params.require(:choice)
          changed(page.document)
        end
      end
    end
  end
end
