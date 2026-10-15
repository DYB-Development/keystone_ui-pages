# frozen_string_literal: true

require "test_helper"

class KeystoneUi::Pages::EditorPropsTest < ActionDispatch::IntegrationTest
  test "the builder hands the editor each element's icon and group" do
    page = KeystoneUi::Pages::Page.create!(name: "Pricing", slug: "pricing")

    get "/pages/manage/pages/#{page.id}"

    props = JSON.parse(Nokogiri::HTML(response.body).at_css("[data-react-ui]")["data-props"])
    assert_equal %w[group icon], props["elements"].first.keys.grep(/\A(icon|group)\z/).sort
  end

  test "the builder hands the editor the layout defaults and the equal shares of a row" do
    page = KeystoneUi::Pages::Page.create!(name: "Pricing", slug: "pricing")

    get "/pages/manage/pages/#{page.id}"

    props = JSON.parse(Nokogiri::HTML(response.body).at_css("[data-react-ui]")["data-props"])
    assert_equal [ "md", "1/2" ], [ props.dig("defaults", "row", "gap"), props.dig("shares", "2") ]
  end

  test "the builder hands the editor the alignment each element starts with" do
    page = KeystoneUi::Pages::Page.create!(name: "Pricing", slug: "pricing")

    get "/pages/manage/pages/#{page.id}"

    props = JSON.parse(Nokogiri::HTML(response.body).at_css("[data-react-ui]")["data-props"])
    assert_equal "start", props["elements"].find { |element| element["key"] == "button" }["align"]
  end

  test "the builder hands the editor the named values a page may use with their labels" do
    KeystoneUi::Pages::Values.names = { "client_name" => "Client name" }
    page = KeystoneUi::Pages::Page.create!(name: "Pricing", slug: "pricing")

    get "/pages/manage/pages/#{page.id}"

    props = JSON.parse(Nokogiri::HTML(response.body).at_css("[data-react-ui]")["data-props"])
    assert_equal({ "client_name" => "Client name" }, props["value_names"])
  ensure
    KeystoneUi::Pages::Values.names = {}
  end

  test "the builder hands the editor the samples to choose from and the one in use" do
    KeystoneUi::Pages::Values.chooser = ->(_page) { [ [ "Acme", "acme" ], [ "Globex", "globex" ] ] }
    page = KeystoneUi::Pages::Page.create!(name: "Pricing", slug: "pricing")

    get "/pages/manage/pages/#{page.id}"

    props = JSON.parse(Nokogiri::HTML(response.body).at_css("[data-react-ui]")["data-props"])
    assert_equal [ [ [ "Acme", "acme" ], [ "Globex", "globex" ] ], "acme" ], [ props["samples"], props["sample"] ]
  ensure
    KeystoneUi::Pages::Values.chooser = nil
  end
end
