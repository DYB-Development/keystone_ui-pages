# frozen_string_literal: true

module KeystoneUi
  module Pages
    module Values
      class << self
        attr_writer :names
        attr_accessor :provider, :chooser

        def names
          @names ||= {}
        end

        def label(name)
          names[name.to_s]
        end

        def samples_for(page)
          chooser ? chooser.call(page).to_a : []
        end

        def sample(page, choice)
          provider ? provider.call(page, choice).to_h.stringify_keys : {}
        end
      end
    end
  end
end
