# frozen_string_literal: true

module KeystoneUi
  module Pages
    module Manage
      class SequencePagesController < BaseController
        before_action :find_sequence
        before_action :find_removable_page, only: %i[remove destroy]

        def new
          @default_name = Page.new(place: params[:place], owner: page_owner).default_name
          @copyable_pages = copyable_pages
        end

        def create
          open_page = @sequence.pages.find { |page| page.id.to_s == params[:after_id].to_s }
          page = Page.create!(params.require(:page).permit(:name).merge(place: params[:place], sequence_key: params[:key], owner: page_owner, **copied_document))
          send(KeystoneUi::Pages.place_settings.dig(params[:place], :adds_page_method), params[:key], page, open_page)
          redirect_to manage_sequence_path(params[:place], params[:key], page_id: page.id)
        end

        def remove; end

        def destroy
          position = @sequence.pages.index(@page)
          page_before = @sequence.pages[position - 1] if position.positive?
          Page.transaction do
            @page.archive
            send(removes_page_method, params[:key], @page)
          end
          redirect_to manage_sequence_path(params[:place], params[:key], page_id: page_before&.id)
        end

        private

        def find_sequence
          @sequence = sequence(params[:place], params[:key])
          refuse unless @sequence
        end

        def find_removable_page
          @page = @sequence.pages.find { |entry| entry.id.to_s == params[:id] }
          refuse unless removes_page_method && @page
        end

        def copyable_pages
          owned_pages.current.where(place: params[:place])
        end

        def copied_document
          source = copyable_pages.find_by(id: params[:copy_of_id]) if params[:copy_of_id].present?
          source ? { document: source.document } : {}
        end

        def removes_page_method
          KeystoneUi::Pages.place_settings.dig(params[:place], :removes_page_method)
        end
      end
    end
  end
end
