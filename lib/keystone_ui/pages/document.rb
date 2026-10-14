# frozen_string_literal: true

require "securerandom"

module KeystoneUi
  module Pages
    module Document
      SCHEMA_VERSION = 1

      module_function

      def blank
        { "schema_version" => SCHEMA_VERSION, "sections" => [ section ] }
      end

      def section
        { "id" => SecureRandom.uuid, "rows" => [ row ] }
      end

      def row
        { "id" => SecureRandom.uuid, "columns" => [ column ] }
      end

      def column
        { "id" => SecureRandom.uuid, "elements" => [] }
      end
    end
  end
end
