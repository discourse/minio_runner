# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path("../lib", __dir__)
require "minio_runner"

require "minitest/autorun"
require "minitest/color"
require "minitest/reporters"
require "pry"
require "pry-byebug"

# c.f. https://gist.github.com/jazzytomato/79bb6ff516d93486df4e14169f4426af
def mock_env(partial_env_hash)
  old = ENV.to_hash
  ENV.update partial_env_hash
  begin
    yield
  ensure
    ENV.replace old
  end
end

Minitest::Reporters.use! Minitest::Reporters::SpecReporter.new
