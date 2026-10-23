# frozen_string_literal: true

module KeystoneUi
  module Pages
    class Catalog
      Element = Data.define(:key, :name, :component, :fields, :body, :icon, :group, :align, :placed)

      def initialize
        @elements = {}
      end

      def register(key:, name:, component:, fields:, body: nil, icon: nil, group: nil, align: nil, placed: false)
        @elements[key.to_sym] = Element.new(key: key.to_sym, name: name, component: component, fields: fields, body: body, icon: icon, group: group, align: align, placed: placed)
      end

      def leave_out(*keys)
        keys.each { |key| @elements.delete(key.to_sym) }
      end

      def without(*keys)
        Catalog.new.tap { |copy| elements.each { |element| copy.add(element) unless keys.include?(element.key) } }
      end

      def elements
        @elements.values
      end

      def find(key)
        @elements[key.to_sym]
      end

      protected

      def add(element)
        @elements[element.key] = element
      end
    end
  end
end
