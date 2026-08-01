# frozen_string_literal: true

require_relative "lib/tedo/version"

Gem::Specification.new do |spec|
  spec.name          = "tedo"
  spec.version       = Tedo::VERSION
  spec.authors       = ["Tedo"]
  spec.email         = ["support@tedo.ai"]

  spec.summary       = "Ruby client for the Tedo API"
  spec.description   = "Official Ruby library for the Tedo API. Manage billing, subscriptions, and more."
  spec.homepage      = "https://github.com/tedo-ai/tedo-ruby"
  spec.license       = "MIT"
  spec.required_ruby_version = ">= 3.0.0"

  spec.files         = Dir["lib/**/*", "LICENSE", "README.md"]
  spec.require_paths = ["lib"]

  spec.add_dependency "faraday", ">= 1.0", "< 3.0"
end
