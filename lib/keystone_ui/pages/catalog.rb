# frozen_string_literal: true

module KeystoneUi
  module Pages
    class Catalog
      Element = Data.define(:key, :name, :component, :fields, :body, :icon, :group, :align)

      def initialize
        @elements = {}
      end

      def register(key:, name:, component:, fields:, body: nil, icon: nil, group: nil, align: nil)
        @elements[key.to_sym] = Element.new(key: key.to_sym, name: name, component: component, fields: fields, body: body, icon: icon, group: group, align: align)
      end

      def leave_out(*keys)
        keys.each { |key| @elements.delete(key.to_sym) }
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
