class ApplicationController < ActionController::Base
  def refuse_page
    render plain: "This page is not available", status: :forbidden
  end

  def current_team
    Team.find_by(name: request.headers["X-Team"])
  end
end
