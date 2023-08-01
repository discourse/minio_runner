# frozen_string_literal: true

module MinioRunner
  class Config
    attr_accessor :install_dir

    DEFAULT_INSTALL_DIR = "~/.minio_runner"
    DEFAULT_CACHE_TIME = 86_400 # 24 hours in seconds

    CONFIGURABLE_ENV_VARS = {
      install_dir: "Path to install minio_runner (default #{DEFAULT_INSTALL_DIR})",
      log_level:
        "Log level for minio_runner (DEBUG, INFO, WARN, ERROR, FATAL, UNKNOWN, default INFO)",
      cache_time:
        "Time in seconds to cache minio_runner downloads for both the minio server and mc binaries (default 86400 seconds)",
    }

    def initialize
      self.install_dir = System.env(:install_dir) || DEFAULT_INSTALL_DIR
    end
  end
end
