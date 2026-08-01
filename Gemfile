# frozen_string_literal: true

source "https://rubygems.org"

gemspec

group :development, :test do
  # RuboCop permits parallel 2.x, but parallel 2.x requires Ruby 3.3 while the
  # SDK supports Ruby 3.0. Keep the development lock usable at our floor.
  gem "parallel", "< 2.0", require: false
  gem "rspec", "~> 3.13"
  gem "rubocop", "~> 1.75", require: false
end
