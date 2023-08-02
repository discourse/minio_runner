# frozen_string_literal: true

module MinioRunner
  class McManager
    class << self
      def command
        ["#{MinioRunner::McBinary.binary_file_path}"]
      end

      def bucket_exists?(alias_name, name)
        system(*command.concat(["ls", "#{alias_name}/#{name}"]))
      end

      def create_bucket(alias_name, name)
        MinioRunner.logger.debug("Creating bucket #{alias_name}/#{name}...")
        if !bucket_exists?(alias_name, name)
          system(*command.concat(["mb", "#{alias_name}/#{name}"]))
          MinioRunner.logger.debug("Created  #{alias_name}/#{name}.")
        else
          MinioRunner.logger.debug("Bucket #{alias_name}/#{name} already exists, doing nothing.")
        end
      end

      def set_alias(name, url)
        MinioRunner.logger.debug("Setting alias #{name} to #{url}...")
        system(
          *command.concat(
            [
              "alias",
              "set",
              name,
              url,
              MinioRunner.config.minio_root_user,
              MinioRunner.config.minio_root_password,
            ],
          ),
        )
        MinioRunner.logger.debug("Set alias #{name} to #{url}.")
      end

      def set_anon(alias_name, bucket, policy)
        MinioRunner.logger.debug(
          "Setting anonymous access for #{alias_name}/#{bucket} to policy #{policy}...",
        )
        system(*command.concat(["anonymous", "set", policy, "#{alias_name}/#{bucket}"]))
        MinioRunner.logger.debug("Anonymous access set for #{alias_name}/#{bucket}.")
      end
    end
  end
end
