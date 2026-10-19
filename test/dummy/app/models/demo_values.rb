class DemoValues
  CLIENT_NAME = "Acme".freeze

  def self.for(visitor)
    return { "signed_in" => "no", "purchased" => "no" } if visitor == "visitor"

    { "signed_in" => "yes", "purchased" => "no", "client_name" => CLIENT_NAME }
  end
end
