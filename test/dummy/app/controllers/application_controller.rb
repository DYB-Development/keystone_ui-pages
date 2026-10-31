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

  def may_view_place?(page)
    page.access_exception == "public_preview" || page.place != "client_portal" || request.headers["X-Client"].present?
  end

  def may_view_demo_page?(page)
    DemoAccess.allows?(page, demo_visitor)
  end

  def demo_page_values(_page)
    DemoValues.for(demo_visitor)
  end

  def demo_visitor
    session[:demo_visitor] || "visitor"
  end

  def visitor_page_values(_page)
    { "owner" => request.headers["X-Owner"], "client_name" => request.headers["X-Client-Name"] }.compact
  end

  def funnel_sequence(key)
    return if request.headers["X-Sequence"] == "refused"

    KeystoneUi::Pages::Sequence.new(title: "Spring sale funnel", pages: KeystoneUi::Pages::Page.where(sequence_key: key).order(:name).to_a, back_url: "/funnels/#{key}")
  end

  def may_edit_pages?
    request.headers["X-Editor"] != "refused"
  end
end
