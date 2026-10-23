# frozen_string_literal: true

module KeystoneUi
  module Pages
    Submission = Data.define(:page, :version, :form_name, :element_id, :values, :request)
  end
end
