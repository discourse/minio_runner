# frozen_string_literal: true

require "net/http"
require "tempfile"

module MinioRunner
  class Network
    class << self
      def get(url)
        MinioRunner.logger.debug("Making network call to #{url}")

        begin
          response = Net::HTTP.get_response(URI(url))
        rescue SocketError
          raise "Can not reach #{url}"
        end

        MinioRunner.logger.debug("Get response: #{response.inspect}")

        case response
        when Net::HTTPSuccess
          response.body
        else
          raise "#{response.class::EXCEPTION_TYPE}: #{response.code} \"#{response.message}\" with #{url}"
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
