# frozen_string_literal: true

require "logger"
require_relative "minio_runner/version"
require_relative "minio_runner/system"
require_relative "minio_runner/config"
require_relative "minio_runner/minio_binary"
require_relative "minio_runner/mc_binary"
require_relative "minio_runner/binary_manager"
require_relative "minio_runner/minio_health_check"
require_relative "minio_runner/minio_server_manager"
require_relative "minio_runner/mc_manager"

module MinioRunner
  class << self
    @@started = false

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

            original_formatter = logger.formatter || Logger::Formatter.new
            logger.formatter =
              proc do |severity, time, progname, msg|
                original_formatter.call(severity, time, progname, "[MinioRunner]: #{msg.strip}")
              end
          end
    end

    def start(install: true)
      logger.debug("Starting minio_runner...")

      install_binaries if install
      start_server
      setup_alias
      setup_buckets

      logger.debug("Started minio_runner.")

      @@started = true
    end

    def started?
      @@started
    end

    def install_binaries
      System.validate_platform
      System.make_install_dir
      MinioRunner::BinaryManager.install(MinioRunner::McBinary)
      MinioRunner::BinaryManager.install(MinioRunner::MinioBinary)
    end

    def start_server
      MinioRunner::MinioServerManager.start
    end

    def setup_alias
      MinioRunner::McManager.set_alias("local", "http://localhost:#{MinioRunner.config.minio_port}")
    end

    def setup_buckets
      MinioRunner.config.buckets.each do |bucket|
        MinioRunner::McManager.create_bucket("local", bucket)
      end
      MinioRunner.config.public_buckets.each do |bucket|
        MinioRunner::McManager.set_anon("local", bucket, "public")
      end
    end

    def stop
      return if !started?
      logger.debug("Stopping minio_runner...")
      MinioRunner::MinioServerManager.stop
      logger.debug("Stopped minio_runner.")
      @@started = false
    end

    def reset_config!
      @config = nil
    end

    def remove_install_dir
      logger.info("Removing MinioRunner install directory at #{MinioRunner.config.install_dir}...")
      FileUtils.rm_rf(MinioRunner.config.install_dir) if Dir.exist?(MinioRunner.config.install_dir)
      logger.info("Done removing MinioRunner install directory.")
    end
  end
end
