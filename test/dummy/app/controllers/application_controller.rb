class ApplicationController < ActionController::Base
  def refuse_page
    render plain: "This page is not available", status: :forbidden
  end
end
