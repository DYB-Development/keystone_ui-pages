class DemoAccess
  ALLOWED_VISITORS = {
    "client_portal" => %w[signed_in_client purchased_client],
    "paid_content" => %w[purchased_client]
  }.freeze

  def self.allows?(page, visitor)
    return true if page.access_exception == "public_preview"

    ALLOWED_VISITORS.fetch(page.place, [ visitor ]).include?(visitor)
  end
end
