# frozen_string_literal: true

require_relative "system"

module MinioRunner
  class BaseBinary
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

      def platform_binary_url
        "#{platform_base_url}#{name}"
      end

      def platform_sha256sum_url
        "#{platform_binary_url}.sha256sum"
      end

      def name
        raise NotImplementedError
      end

      def base_url
        raise NotImplementedError
      end

      def platform_base_url
        raise NotImplementedError
      end
    end
  end
end
