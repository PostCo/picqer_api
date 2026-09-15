# frozen_string_literal: true

require_relative "lib/picqer_api/version"

Gem::Specification.new do |spec|
  spec.name = "picqer_api"
  spec.version = PicqerAPI::VERSION
  spec.authors = ["PostCo"]
  spec.email = ["engineering@postco.co"]

  spec.summary = "Rails-independent Ruby client for the Picqer API"
  spec.description = "A small Ruby client foundation for integrating with the Picqer WMS API without depending on Rails."
  spec.homepage = "https://github.com/PostCo/picqer_api"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.3.0"

  spec.metadata["source_code_uri"] = spec.homepage
  spec.metadata["changelog_uri"] = "#{spec.homepage}/blob/main/CHANGELOG.md"
  spec.metadata["rubygems_mfa_required"] = "true"

  spec.files = Dir["lib/**/*", "CHANGELOG.md", "README.md", "LICENSE.txt"]
  spec.require_paths = ["lib"]

  spec.add_dependency "faraday", "~> 2.0"
  spec.add_dependency "faraday-net_http", ">= 2.0"
  spec.add_dependency "activesupport", ">= 7.0"
  # Default gems in Ruby 3.3, bundled gems from 3.4 onward.
  spec.add_dependency "base64"
  spec.add_dependency "ostruct"

  spec.add_development_dependency "rake"
  spec.add_development_dependency "minitest", "~> 5.0"
  spec.add_development_dependency "webmock", "~> 3.0"
  spec.add_development_dependency "standard"
end
