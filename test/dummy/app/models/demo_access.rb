class DemoAccess
  CLIENTS = %w[signed_in_client purchased_client].freeze

  def self.allows?(page, visitor)
    page.place != "client_portal" || CLIENTS.include?(visitor)
  end
end
