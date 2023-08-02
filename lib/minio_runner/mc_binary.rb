# frozen_string_literal: true

require_relative "base_binary"

module MinioRunner
  class McBinary < BaseBinary
    class << self
      def name
        "mc"
      end

      def base_url
        "https://dl.min.io/client/mc/release"
      end

      def platform_binary_url
        "#{platform_base_url}#{name}"
      end

      def platform_sha256sum_url
        "#{platform_binary_url}.sha256sum"
      end

      def platform_base_url
        if System.linux?
          "#{base_url}/linux-amd64/"
        elsif System.mac?
          System.mac_m? ? "#{base_url}/darwin-arm64/" : "#{base_url}/darwin-amd64/"
        end
      end
    end
  end
end
