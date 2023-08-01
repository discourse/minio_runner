# frozen_string_literal: true

module MinioRunner
  class BinaryManager
    MC_BINARY = { name: "mc", url: "https://dl.min.io/client/mc/release/" }
    MINIO_BINARY = { name: "minio", url: "https://dl.min.io/server/minio/release/" }

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
      if !installed?
      else
      end
    end

    def installed?
      File.exist?("#{MinioRunner.config.install_path}/#{binary[:name]}")
    end
  end
end
