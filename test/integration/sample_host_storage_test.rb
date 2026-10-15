# frozen_string_literal: true

require "test_helper"

class KeystoneUi::Pages::SampleHostStorageTest < ActiveSupport::TestCase
  test "the sample host stores files with Active Storage, as a host keeping PDFs does" do
    blob = ActiveStorage::Blob.create_and_upload!(io: StringIO.new("%PDF-1.4"), filename: "report.pdf", content_type: "application/pdf")

    assert_equal "%PDF-1.4", blob.download
  end
end
