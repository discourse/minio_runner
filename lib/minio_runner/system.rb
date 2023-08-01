# frozen_string_literal: true

require "fileutils"

module MinioRunner
  class System
    class InvalidEnvVar < StandardError
    end
    class InvalidPlatform < StandardError
    end

    ENV_VAR_PREFIX = "MINIO_RUNNER_"

    class << self
      def env(name)
        name = name.to_sym

        if !defined_env?(name)
          raise MinioRunner::System::InvalidEnvVar.new(
                  "Environment variable #{ENV_VAR_PREFIX}#{name.upcase} is not valid for minio_runner.",
                )
        end

        ENV["#{ENV_VAR_PREFIX}#{name.upcase}"]
      end

      def defined_env?(name)
        MinioRunner::Config::CONFIGURABLE_ENV_VARS.keys.include?(name)
      end

      def make_install_dir
        if !Dir.exist?(MinioRunner.config.install_dir)
          MinioRunner.logger.debug("Making install directory #{MinioRunner.config.install_dir}.")
          FileUtils.mkdir_p(MinioRunner.config.install_dir)
        end
      end

      def validate_platform
        if !mac? || linux?
          raise MinioRunner::System::InvalidPlatform.new(
                  "MinioRunner only supports Mac, macOS and Linux.",
                )
        end
      end

      def mac?
        Gem::Platform.local.os[/darwin|mac os/]
      end

      def linux?
        Gem::Platform.local.os[/linux/]
      end
    end
  end
end
