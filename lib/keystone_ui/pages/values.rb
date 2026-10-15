# frozen_string_literal: true

module KeystoneUi
  module Pages
    module Values
      class << self
        attr_writer :names

        def names
          @names ||= {}
        end

        def label(name)
          names[name.to_s]
        end
      end
    end
  end
end
