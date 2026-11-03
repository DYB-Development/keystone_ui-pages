# frozen_string_literal: true

module KeystoneUi
  module Pages
    module Manage
      class SequencesController < BaseController
        def show
          @sequence = sequence(params[:place], params[:key])
          return refuse unless @sequence

          @page = params[:page_id] ? @sequence.pages.find { |page| page.id.to_s == params[:page_id] } : @sequence.pages.first
        end

        def publish
          publishes = KeystoneUi::Pages.place_settings.dig(params[:place], :publishes_sequence_method)
          published = sequence(params[:place], params[:key])
          return refuse unless publishes && published

          begin
            send(publishes, params[:key])
            flash[:sequence_notice] = "#{published.title} is published."
          rescue SequencePublishRefused => refusal
            flash[:sequence_refusal] = refusal.message
          end
          redirect_to manage_sequence_path(params[:place], params[:key], page_id: params[:page_id])
        end
      end
    end
  end
end
