# frozen_string_literal: true

module KeystoneUi
  module Pages
    Sequence = Data.define(:title, :pages, :back_url)
    SequencePublishRefused = Class.new(StandardError)
  end
end
