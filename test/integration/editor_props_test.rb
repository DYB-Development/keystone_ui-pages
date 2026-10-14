# frozen_string_literal: true

require "test_helper"

class KeystoneUi::Pages::EditorPropsTest < ActionDispatch::IntegrationTest
  test "the builder hands the editor each element's icon and group" do
    page = KeystoneUi::Pages::Page.create!(name: "Pricing", slug: "pricing")

    get "/pages/manage/pages/#{page.id}"

    props = JSON.parse(Nokogiri::HTML(response.body).at_css("[data-react-ui]")["data-props"])
    assert_equal %w[group icon], props["elements"].first.keys.grep(/\A(icon|group)\z/).sort
  end
end
