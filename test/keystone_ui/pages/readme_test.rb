# frozen_string_literal: true

require "test_helper"

class KeystoneUi::Pages::ReadmeTest < ActiveSupport::TestCase
  test "the README names every keystone_ui component the catalog leaves out" do
    components = Dir[Gem.loaded_specs["keystone_ui"].full_gem_path + "/app/components/keystone/ui/*_component.rb"].map { |path| File.basename(path, "_component.rb") }
    offered = KeystoneUi::Pages::Catalog.new.tap { |catalog| KeystoneUi::Pages::KeystoneElements.register(catalog) }.elements.map { |element| element.component.to_s.delete_prefix("ui_") }
    readme = KeystoneUi::Pages::Engine.root.join("README.md").read

    assert_equal [], (components - offered).reject { |component| readme.include?("`#{component}`") }
  end

  test "the README's list of left-out components names none the catalog offers" do
    offered = KeystoneUi::Pages::Catalog.new.tap { |catalog| KeystoneUi::Pages::KeystoneElements.register(catalog) }.elements.map { |element| element.component.to_s.delete_prefix("ui_") }
    left_out = KeystoneUi::Pages::Engine.root.join("README.md").read.split("### Components left out of the catalog").last

    assert_equal [], offered.select { |component| left_out.include?("`#{component}`") }
  end
end
