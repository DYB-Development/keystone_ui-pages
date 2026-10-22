# frozen_string_literal: true

require "test_helper"

class KeystoneUi::Pages::NewPageDefaultsTest < ActionDispatch::IntegrationTest
  test "a page created with no name is given a default name" do
    post "/pages/manage/pages", params: { page: { name: "", slug: "pricing" } }

    assert_equal "Untitled page", KeystoneUi::Pages::Page.find_by(slug: "pricing").name
  end
end
