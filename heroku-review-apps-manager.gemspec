# frozen_string_literal: true

require_relative "lib/heroku/review/apps/manager/version"

Gem::Specification.new do |spec|
  spec.name = "heroku-review-apps-manager"
  spec.version = Heroku::Review::Apps::Manager::VERSION
  spec.authors = ["kakudooo"]
  spec.email = ["kakudou3@gmail.com"]

  spec.summary = "A CLI tool to manage Heroku Review Apps"
  spec.description = "heroku-review-apps-manager provides a command-line interface to list, create, and delete Heroku review apps associated with GitHub pull requests. It simplifies the management of review apps in your CI/CD pipeline."
  spec.homepage = "https://github.com/kakudou3/heroku-review-apps-manager"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.0.0"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/kakudou3/heroku-review-apps-manager"
  spec.metadata["changelog_uri"] = "https://github.com/kakudou3/heroku-review-apps-manager/blob/main/CHANGELOG.md"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(__dir__) do
    `git ls-files -z`.split("\x0").reject do |f|
      (File.expand_path(f) == __FILE__) ||
        f.start_with?(*%w[bin/ test/ spec/ features/ .git .github appveyor Gemfile])
    end
  end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "faraday"
  spec.add_dependency "octokit"
  spec.add_dependency "platform-api"
  spec.add_dependency "thor"
  spec.add_dependency "whirly"

  spec.add_development_dependency "rake"
  spec.add_development_dependency "rspec"
  spec.add_development_dependency "rubocop"
end
