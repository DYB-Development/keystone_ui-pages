# frozen_string_literal: true

module KeystoneUi
  module Pages
    module Manage
      class LivesController < BaseController
        layout -> { KeystoneUi::Pages.layout }

        def show
          page = owned_pages.find(params[:page_id])
          @version = page.live_version
          return refuse if @version.nil?

          @values = Values.sample(page, helpers.chosen_sample(page))
          render "keystone_ui/pages/pages/show"
        end
      end
    end
  end
end
