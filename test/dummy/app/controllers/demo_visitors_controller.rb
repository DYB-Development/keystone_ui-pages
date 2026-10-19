class DemoVisitorsController < ApplicationController
  VISITORS = %w[visitor signed_in_client purchased_client].freeze

  def update
    session[:demo_visitor] = params[:visitor] if VISITORS.include?(params[:visitor])
    redirect_back fallback_location: "/pages/manage/pages"
  end
end
