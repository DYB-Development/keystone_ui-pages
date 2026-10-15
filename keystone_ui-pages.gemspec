# frozen_string_literal: true

require_relative "lib/keystone_ui/pages/version"

Gem::Specification.new do |spec|
  spec.name = "keystone_ui-pages"
  spec.version = KeystoneUi::Pages::VERSION
  spec.authors = [ "Tyler Schneider" ]
  spec.email = [ "tylercschneider@gmail.com" ]

  spec.summary = "A flow-layout page builder that draws keystone_ui elements."
  spec.description = "Pages kept as versioned JSON documents of sections, rows and columns, changed through named operations and drawn with keystone_ui's components."
  spec.homepage = "https://github.com/DYB-Development/keystone_ui-pages"
  spec.license = "MIT"

  spec.metadata["source_code_uri"] = spec.homepage
  spec.metadata["bug_tracker_uri"] = "#{spec.homepage}/issues"
  spec.metadata["documentation_uri"] = "#{spec.homepage}#readme"
  spec.metadata["rubygems_mfa_required"] = "true"

  spec.required_ruby_version = ">= 3.2.0"

  spec.files = Dir["lib/**/*", "app/**/*", "config/**/*", "db/**/*"] + [ "LICENSE" ]
  spec.require_paths = [ "lib" ]

  spec.add_dependency "rails", ">= 7.1"
  spec.add_dependency "keystone_ui", ">= 0.44.0"
  spec.add_dependency "keystone_ui-styles", ">= 0.21.0"
  spec.add_dependency "keystone_ui-react", ">= 0.1.3"
end
