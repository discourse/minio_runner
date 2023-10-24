# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path("../lib", __dir__)
require "minio_runner"

require "minitest/autorun"
require "minitest/color"
require "minitest/reporters"
require "pry"
require "pry-byebug"
require "spy/integration"
require "date"

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

class TestBinary < MinioRunner::BaseBinary
  class << self
    def sha_file_name
      "#{name}.sha256sum"
    end

    def version_file_name
      "#{name}.version"
    end

    def version_file_path
      File.join(MinioRunner.config.install_dir, version_file_name)
    end

    def checksum_file_path
      File.join(MinioRunner.config.install_dir, sha_file_name)
    end

    def binary_file_path
      File.join(MinioRunner.config.install_dir, name)
    end

    def name
      "testbin"
    end

    def base_url
      "http://test.com/binaries"
    end

    def platform_base_url
      "http://test.com/binaries/#{Gem::Platform.local.os}"
    end
  end
end

MinioRunner.logger.level = Logger::FATAL

Minitest::Reporters.use! Minitest::Reporters::SpecReporter.new
