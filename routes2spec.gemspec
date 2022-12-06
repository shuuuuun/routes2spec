# frozen_string_literal: true

require_relative "lib/routes2spec/version"

Gem::Specification.new do |spec|
  spec.name = "routes2spec"
  spec.version = Routes2spec::VERSION
  spec.authors = ["shuuuuuny"]
  spec.email = []

  spec.summary = "Generate Request specs and Routing specs of RSpec, from your Rails routes config."
  spec.description = "Generate Request specs and Routing specs of RSpec, from your Rails routes config. It is useful as a test scaffolding."
  spec.homepage = "https://github.com/shuuuuun/routes2spec"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 2.7.0"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/shuuuuun/routes2spec"
  spec.metadata["changelog_uri"] = "https://github.com/shuuuuun/routes2spec/CHANGELOG.md"
  spec.metadata["rubygems_mfa_required"] = "true"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    `git ls-files -z`.split("\x0").reject do |f|
      (f == __FILE__) || f.match(%r{\A(?:(?:bin|test|spec|features)/|\.(?:git|travis|circleci)|appveyor)})
    end
  end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "rails", ">= 6.0"
  # spec.add_dependency "rspec", ">= 3.9"

  # For more information and examples about making a new gem, check out our
  # guide at: https://bundler.io/guides/creating_gem.html
end
