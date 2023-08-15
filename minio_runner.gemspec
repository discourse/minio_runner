# frozen_string_literal: true

require_relative "lib/minio_runner/version"

Gem::Specification.new do |spec|
  spec.name = "minio_runner"
  spec.version = MinioRunner::VERSION
  spec.summary = "Manages local minio binary installs"
  spec.description =
    "Manages local minio binary installs and handles stopping and starting minio server"
  spec.authors = ["Martin Brennan"]
  spec.email = "martin@discourse.org"
  spec.homepage = "https://rubygemspec.org/gems/minio_runner"
  spec.license = "MIT"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files =
    # rubocop:disable Discourse/NoChdir
    Dir.chdir(__dir__) do
      `git ls-files -z`.split("\x0")
        .reject do |f|
          (File.expand_path(f) == __FILE__) ||
            f.start_with?(*%w[bin/ test/ spec/ features/ .git .github .streerc .rubocop.yml])
        end
    end
  spec.require_paths = ["lib"]

  spec.add_development_dependency "syntax_tree"
  spec.add_development_dependency "syntax_tree-disable_ternary"
  spec.add_development_dependency "rubocop-discourse"
  spec.add_development_dependency "minitest-color"
  spec.add_development_dependency "minitest-reporters"
  spec.add_development_dependency "minitest-line"
  spec.add_development_dependency "spy"
  spec.add_development_dependency "pry"
  spec.add_development_dependency "pry-byebug"
end
