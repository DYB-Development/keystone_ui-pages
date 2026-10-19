class DemoAccess
  CLIENTS = %w[signed_in_client purchased_client].freeze

  def self.allows?(page, visitor)
    page.access_exception == "public_preview" || page.place != "client_portal" || CLIENTS.include?(visitor)
  end
end
