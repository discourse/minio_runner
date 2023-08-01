# frozen_string_literal: true

require "logger"
require_relative "minio_runner/version"
require_relative "minio_runner/system"
require_relative "minio_runner/config"

module MinioRunner
  class << self
    def config(&block)
      @config ||= MinioRunner::Config.new
      if block_given?
        yield @config
      else
        @config
      end
    end

    def logger
      @logger ||=
        Logger
          .new(STDOUT)
          .tap do |logger|
            logger.level =
              (
                if System.env(:log_level)
                  Kernel.const_get("Logger::#{System.env(:log_level)}")
                else
                  Logger::INFO
                end
              )
          end
    end

    def start
      logger.debug("Starting minio_runner...")
      System.validate_platform
      System.make_install_dir
      MinioRunner::BinaryManager.install(MinioRunner::MC_BINARY)
      MinioRunner::BinaryManager.install(MinioRunner::MINIO_BINARY)
      logger.debug("Started minio_runner.")
    end

    def stop
      logger.debug("Stopping minio_runner...")
      logger.debug("Stopped minio_runner.")
    end

    def reset!
      @config = nil
    end
  end
end
