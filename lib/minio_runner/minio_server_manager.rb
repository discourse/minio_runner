# frozen_string_literal: true

require_relative "child_process"

module MinioRunner
  class MinioServerManager
    SERVER_STOP_TIMEOUT_SECONDS = 5

    attr_reader :pid, :process

    class << self
      def start
        @server = new
        @server.start
      end

      def stop
        return if @server.nil?
        @server.stop
      end

      def log_file_path
        "#{MinioRunner.config.install_dir}/minio.log"
      end
    end

    def start
      if process_running?
        MinioRunner.logger.debug("Already started minio server.")
        return
      end

      MinioRunner.logger.debug("Starting minio server...")

      MinioRunner::System.exit_hook { stop }

      @process =
        MinioRunner::ChildProcess.build(
          server_command,
          env: {
            "MINIO_ROOT_USER" => MinioRunner.config.minio_root_user,
            "MINIO_ROOT_PASSWORD" => MinioRunner.config.minio_root_password,
            "MINIO_DOMAIN" => MinioRunner.config.minio_domain,
          },
          log_file: MinioServerManager.log_file_path,
        )

      @process.start

      # Make sure the minio server is ready to accept requests.
      health_check(retries: 3)

      MinioRunner.logger.debug("minio server running at pid #{@process.pid}!")
    end

    def stop
      return if process_exited?

      MinioRunner.logger.debug("Stopping minio server running at pid #{@pid}...")
      @process.stop(SERVER_STOP_TIMEOUT_SECONDS)
      @process = nil
      MinioRunner.logger.debug("minio server stopped")
    end

    def process_running?
      defined?(@process) && @process&.alive?
    end

    def process_exited?
      @process.nil? || @process.exited?
    end

    private

    def server_command
      command = []

      # server start command for minio
      command << "#{MinioRunner::MinioBinary.binary_file_path} server #{MinioRunner.config.minio_data_directory}"

      # flags for minio
      command << "--console-address :#{MinioRunner.config.minio_console_port}"
      command << "--address #{MinioRunner.config.minio_domain}:#{MinioRunner.config.minio_port}"

      command
    end

    def health_check(retries:)
      begin
        Network.get("#{MinioRunner.config.minio_server_url}/minio/health/live")
      rescue StandardError
        if retries.positive?
          sleep 1
          health_check(retries: retries - 1)
        else
          raise "Minio server failed to start."
        end
      end
    end
  end
end
