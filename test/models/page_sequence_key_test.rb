# frozen_string_literal: true

require "test_helper"

class KeystoneUi::Pages::PageSequenceKeyTest < ActiveSupport::TestCase
  test "giving a page another sequence key after it was made is refused" do
    page = KeystoneUi::Pages::Page.create!(name: "Landing", slug: "landing", sequence_key: "spring-sale")

    assert_raises(ActiveRecord::ReadonlyAttributeError) { page.update!(sequence_key: "winter-sale") }
  end
end
