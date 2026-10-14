# frozen_string_literal: true

module KeystoneUi
  module Pages
    class Catalog
      Element = Data.define(:key, :name, :component, :fields, :body)

      def initialize
        @elements = {}
      end

      def register(key:, name:, component:, fields:, body: nil)
        @elements[key.to_sym] = Element.new(key: key.to_sym, name: name, component: component, fields: fields, body: body)
      end

      def elements
        @elements.values
      end

      def find(key)
        @elements[key.to_sym]
      end
    end
  end
end
