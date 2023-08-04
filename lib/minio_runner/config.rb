# frozen_string_literal: true

module MinioRunner
  class Config
    attr_accessor :install_dir, :cache_time, :buckets, :public_buckets, :log_level
    attr_accessor :minio_data_directory,
                  :minio_root_user,
                  :minio_root_password,
                  :minio_domain,
                  :minio_port,
                  :minio_console_port

    DEFAULT_INSTALL_DIR = "~/.minio_runner"
    DEFAULT_CACHE_TIME = 86_400 # 24 hours in seconds

    DEFAULT_MINIO_SERVER_DATA_DIR = "~/.minio_runner/data"
    DEFAULT_MINIO_PORT = 9000
    DEFAULT_MINIO_CONSOLE_PORT = 9001
    DEFAULT_MINIO_ROOT_USER = "minioadmin"
    DEFAULT_MINIO_ROOT_PASSWORD = "minioadmin"

    CONFIGURABLE_ENV_VARS = {
      install_dir: "Path to install minio_runner (default #{DEFAULT_INSTALL_DIR})",
      log_level:
        "Log level for minio_runner (DEBUG, INFO, WARN, ERROR, FATAL, UNKNOWN, default INFO)",
      cache_time:
        "Time in seconds to cache minio_runner downloads for both the minio server and mc binaries (default #{DEFAULT_CACHE_TIME} seconds)",
      buckets: "List of buckets to create on startup, comma separated.",
      public_buckets: "List of buckets to make public for anonymous users, comma separated.",
      minio_domain: "Domain to use for minio server (default localhost)",
      minio_data_directory:
        "Path to minio server data directory (default #{DEFAULT_MINIO_SERVER_DATA_DIR})",
      minio_root_user: "User for minio server root user (default #{DEFAULT_MINIO_ROOT_USER})",
      minio_root_password:
        "Password for minio server root user (default #{DEFAULT_MINIO_ROOT_PASSWORD})",
      minio_console_port: "Port for minio server console (default #{DEFAULT_MINIO_CONSOLE_PORT})",
      minio_port: "Port for minio server (default #{DEFAULT_MINIO_PORT})",
    }

    def initialize
      self.install_dir = System.env(:install_dir) || DEFAULT_INSTALL_DIR
      self.cache_time = System.env(:cache_time) || DEFAULT_CACHE_TIME
      self.buckets = System.env(:buckets)&.split(",") || []
      self.public_buckets = System.env(:public_buckets)&.split(",") || []

      # minio server configuration
      self.minio_data_directory = System.env(:minio_data_directory) || DEFAULT_MINIO_SERVER_DATA_DIR
      self.minio_root_user = System.env(:minio_root_user) || DEFAULT_MINIO_ROOT_USER
      self.minio_root_password = System.env(:minio_root_password) || DEFAULT_MINIO_ROOT_PASSWORD
      self.minio_domain = System.env(:minio_domain) || "localhost"
      self.minio_port = System.env(:minio_port) || DEFAULT_MINIO_PORT
      self.minio_console_port = System.env(:minio_console_port) || DEFAULT_MINIO_CONSOLE_PORT
    end

    def install_dir=(dir)
      @install_dir = File.expand_path(dir)
    end

    def minio_data_directory=(dir)
      @minio_data_directory = File.expand_path(dir)
    end

    def minio_server_url
      "http://#{minio_domain}:#{minio_port}"
    end

    def minio_urls
      urls = [minio_server_url]
      buckets.each { |bucket| urls << "http://#{bucket}.#{minio_domain}:#{minio_port}" }
      urls
    end
  end
end
