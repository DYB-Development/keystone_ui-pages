# frozen_string_literal: true

module KeystoneUi
  module Pages
    module Filling
      module_function

      def filled(stored, values)
        return stored.presence unless stored.is_a?(Hash) && stored.key?("value")

        values[stored["value"]].presence || stored["fallback"].presence || ""
      end

      def hidden?(node, values)
        condition = node["show_when"]
        condition && values[condition["value"]].to_s != condition["equals"].to_s
      end
    end
  end
end
