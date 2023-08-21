# frozen_string_literal: true

module MinioRunner
  ##
  # Checks that the minio server is running on the configured port using
  # the /minio/health/live endpoint with a limited number of retries.
  #
  # Also used to check whether /etc/hosts is configured properly; some platforms
  # (read: macOS) have to be configured in a certain way to avoid this.
  class MinioHealthCheck
    class << self
      def call(retries: 2, initial_retries: nil)
        initial_retries ||= retries
        begin
          Network.get("#{MinioRunner.config.minio_server_url}/minio/health/live")
        rescue StandardError, MinioRunner::Network::NetworkError
          if retries.positive?
            sleep 1
            call(retries: retries - 1, initial_retries: initial_retries)
          else
            message =
              "Minio server failed to start after #{initial_retries + 1} attempts. Check that /etc/hosts is configured properly."

            if MinioRunner::System.mac? && MinioRunner.config.minio_domain.ends_with?(".local")
              message += Minio Runner::Network::MAC_OS_LOCAL_DOMAIN_ERROR_MESSAGE
            end

            raise MinioRunner::Network::NetworkError.new(message)
          end
        end
      end
    end
  end
end
