class ApplicationController < ActionController::Base
  helper_method :testimonial

  def testimonial(quote:)
    helpers.tag.blockquote(quote, class: "testimonial")
  end

  def refuse_page
    render plain: "This page is not available", status: :forbidden
  end

  def current_team
    Team.find_by(name: request.headers["X-Team"])
  end

  def may_view_page?(_page)
    request.headers["X-Visitor"] != "blocked"
  end

  def may_edit_pages?
    request.headers["X-Editor"] != "refused"
  end
end
