# frozen_string_literal: true

require_relative "network"

module MinioRunner
  class BinaryManager
    class << self
      def install(binary)
        new(binary).install
      end
    end

    attr_reader :binary

    def initialize(binary)
      @binary = binary
    end

    def install
      if installed?
        if File.exist?(binary.version_file_path)
          if version_cache_expired? && new_version_available?
            MinioRunner.logger.debug("New version of #{binary.name} available. Downloading...")
            download_binary
          else
            MinioRunner.logger.debug("Version for #{binary.name} is up to date.")
          end
        else
          MinioRunner.logger.debug("Version file for #{binary.name} not found. Downloading...")
          download_binary
        end
      else
        MinioRunner.logger.debug("#{binary.name} not installed. Downloading...")
        download_binary
      end
      MinioRunner.logger.debug("#{binary.name} installed successfully!")
    end

    def new_version_available?
      old_version = nil
      new_version = nil

      Network.download(binary.platform_sha256sum_url) do |sha_file|
        new_version = File.read(sha_file.path)
        old_version = File.read(binary.version_file_path)
      end

      old_version != new_version
    end

    def download_binary
      Network.download(binary.platform_binary_url) do |binary_file|
        FileUtils.cp(binary_file, File.join(MinioRunner.config.install_dir, binary.name))
      end

      Network.download(binary.platform_sha256sum_url) do |sha_file|
        FileUtils.cp(sha_file, File.join(MinioRunner.config.install_dir, binary.sha_file_name))
        FileUtils.cp(sha_file, File.join(MinioRunner.config.install_dir, binary.version_file_name))
      end

      FileUtils.chmod("ugo+rx", binary.binary_file_path)
    end

    def installed?
      File.exist?(binary.binary_file_path)
    end

    def version_cache_expired?
      Time.now - File.mtime(binary.version_file_path) < MinioRunner.config.cache_time
    end
  end
end
