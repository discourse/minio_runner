# frozen_string_literal: true

require "open3"

module MinioRunner
  class McManager
    CommandError = Class.new(StandardError)

    DEFAULT_RETRIES = 5
    RETRY_DELAY = 1

    class << self
      def command
        ["#{MinioRunner::McBinary.binary_file_path}"]
      end

      def bucket_exists?(alias_name, name)
        # `mc ls` exits non-zero when the bucket is missing, which is fine here.
        _, _, status = run_mc(["ls", "#{alias_name}/#{name}"], allow_failure: true, retries: 0)
        status.success?
      end

      def create_bucket(alias_name, name)
        MinioRunner.logger.debug("Creating bucket #{alias_name}/#{name}...")
        if !bucket_exists?(alias_name, name)
          run_mc(["mb", "#{alias_name}/#{name}"])
          MinioRunner.logger.debug("Created  #{alias_name}/#{name}.")
        else
          MinioRunner.logger.debug("Bucket #{alias_name}/#{name} already exists, doing nothing.")
        end
      end

      def set_alias(name, url)
        MinioRunner.logger.debug("Setting alias #{name} to #{url}...")
        run_mc(
          [
            "alias",
            "set",
            name,
            url,
            MinioRunner.config.minio_root_user,
            MinioRunner.config.minio_root_password,
          ],
        )
        MinioRunner.logger.debug("Set alias #{name} to #{url}.")
      end

      def set_anon(alias_name, bucket, policy)
        MinioRunner.logger.debug(
          "Setting anonymous access for #{alias_name}/#{bucket} to policy #{policy}...",
        )
        run_mc(["anonymous", "set", policy, "#{alias_name}/#{bucket}"])
        MinioRunner.logger.debug("Anonymous access set for #{alias_name}/#{bucket}.")
      end

      # Captures stdout/stderr to the minio log file, retries with backoff
      # on non-zero exit codes (covers errors like "Server not initialized yet"
      # and "connection refused" when minio is still starting) and raises
      # `CommandError` on actual failures. (unless `allow_failure` is set)
      def run_mc(args, allow_failure: false, retries: DEFAULT_RETRIES)
        full_command = command + args
        max_attempts = retries + 1
        attempts = 0
        stdout = stderr = status = nil

        while attempts < max_attempts
          stdout, stderr, status = Open3.capture3(*full_command)
          File.open(MinioServerManager.log_file_path, "a") { |f| f.write(stdout, stderr) }

          attempts += 1
          break if status.success? || attempts == max_attempts

          MinioRunner.logger.warn(
            "mc #{args.join(" ")} failed (attempt #{attempts}/#{max_attempts}, " \
              "exit #{status.exitstatus}); retrying in #{RETRY_DELAY}s: #{stderr.strip}",
          )
          sleep(RETRY_DELAY)
        end

        return stdout, stderr, status if status.success? || allow_failure

        raise CommandError,
              "mc #{args.join(" ")} failed after #{attempts} attempts " \
                "(exit #{status.exitstatus}): #{stderr.strip}"
      end
    end
  end
end
