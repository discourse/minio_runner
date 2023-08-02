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
    end
  end
end
