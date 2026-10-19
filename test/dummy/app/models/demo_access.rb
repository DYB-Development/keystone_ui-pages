class DemoAccess
  def self.allows?(page, visitor)
    page.place != "client_portal"
  end
end
