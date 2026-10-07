require_relative 'lib/buildkite/version'

Gem::Specification.new do |spec|
  spec.name          = "buildkiterb"
  spec.version       = Buildkite::VERSION
  spec.authors       = ["Dean Perry"]
  spec.email         = ["dean@voupe.com"]

  spec.summary       = "A Ruby library for the Buildkite API"
  spec.homepage      = "https://github.com/d34ndev/buildkiterb"
  spec.license       = "MIT"
  spec.required_ruby_version = Gem::Requirement.new(">= 3.3")

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/d34ndev/buildkiterb"
  spec.metadata["changelog_uri"] = "https://github.com/d34ndev/buildkiterb/blob/main/CHANGELOG.md"
  spec.metadata["bug_tracker_uri"] = "https://github.com/d34ndev/buildkiterb/issues"

  spec.files         = Dir["lib/**/*.rb", "README.md", "LICENSE.txt", "CHANGELOG.md"]
  spec.require_paths = ["lib"]

  spec.add_dependency "faraday", ">= 2.14.3", "< 3"
end
