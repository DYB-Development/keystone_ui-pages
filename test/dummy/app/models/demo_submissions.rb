# frozen_string_literal: true

class DemoSubmissions
  def self.record(submission)
    Rails.logger.info("Form submission on #{submission.page.slug}: #{submission.form_name} #{submission.values.to_json}")
  end
end
