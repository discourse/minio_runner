# frozen_string_literal: true

require "net/http"
require "tempfile"

module MinioRunner
  class Network
    class NetworkError < StandardError
    end

    LONG_RESPONSE_TIME_SECONDS = 3
    MAC_OS_LOCAL_DOMAIN_ERROR_MESSAGE = <<~END
      For macOS, there are some issues which cause large delays for .local domain names. See
      https://superuser.com/a/1297335/245469 and https://stackoverflow.com/a/17982964/875941. To
      resolve this, you need to add IPV6 lookup addresses to the hosts file, and it helps to put
      all the entries on one line.

      ::1 minio.local testbucket.minio.local
      fe80::1%lo0 minio.local testbucket.minio.local
      127.0.0.1 minio.local testbucket.minio.local
    END

    class << self
      def get(url)
        MinioRunner.logger.debug("Making network call to #{url}")
        uri = URI(url)
        response = nil
        request_start_time = Time.now

        begin
          Net::HTTP.start(
            uri.host,
            uri.port,
            use_ssl: uri.scheme == "https",
            read_timeout: 1,
            open_timeout: 1,
            write_timeout: 1,
          ) { |http| response = http.get(uri.path) }
        rescue SocketError, Net::OpenTimeout => err
          MinioRunner.logger.debug(
            "Connection error when checking minio server health: #{err.message}",
          )
          raise MinioRunner::Network::NetworkError.new(
                  "Connection error, cannot reach URL: #{url} (#{err.class})",
                )
        end

        MinioRunner.logger.debug("Get response: #{response.inspect}")

        case response
        when Net::HTTPSuccess
          if (Time.now - request_start_time) > Network::LONG_RESPONSE_TIME_SECONDS &&
               MinioRunner.config.minio_domain.ends_with?(".local") && MinioRunner::System.mac?
            MinioRunner.logger.warn(MAC_OS_LOCAL_DOMAIN_ERROR_MESSAGE)
          end
          response.body
        else
          raise MinioRunner::Network::NetworkError.new(
                  "#{response.class::EXCEPTION_TYPE}: #{response.code} \"#{response.message}\" with #{url}",
                )
        end
      end

      def download(url, &block)
        file_name = File.basename(url)
        tempfile =
          Tempfile.open(["", file_name], binmode: true) do |file|
            file.print Network.get(url)
            file
          end

        raise "Could not download #{url}" unless File.exist?(tempfile.to_path)

        MinioRunner.logger.debug("Successfully downloaded #{tempfile.to_path}")

        yield tempfile if block_given?
      ensure
        tempfile&.close!
      end
    end
  end
end
