# frozen_string_literal: true

require "bundler/gem_tasks"
require "rake/testtask"
require "bundler/setup"
require "minio_runner"
require "pry"

Rake::TestTask.new(:test) do |t|
  t.libs << "test"
  t.libs << "lib"
  t.test_files = FileList["test/**/test_*.rb"]
end

task default: :test

namespace :minio_runner do
  desc "Completely removes the minio runner install directory which includes binaries and version files"
  task :remove do
    MinioRunner.remove_install_dir
  end

  desc "Installs the minio and mc binaries"
  task :install do
    MinioRunner.install_binaries
  end

  desc "Forces an update of the binaries. Equivalent to running the remove then install tasks."
  task :install do
    MinioRunner.remove_install_dir
    MinioRunner.install_binaries
  end

  desc "Installs binaries, starts the minio server, and makes sure it is set up to receive requests. Stops server on exit."
  task :start do
    MinioRunner.start
    MinioRunner.logger.info("Minio server is now started. Press any key to stop.")
    STDIN.gets.strip
  end

  desc "Lists all environment varibales that can be configured for MinioRunner"
  task :list_configurable_env do
    puts "These are the configurable environment variables for MinioRunner:"
    puts "-" * 20

    MinioRunner::Config::CONFIGURABLE_ENV_VARS
      .sort_by { |key| key }
      .each do |key, value|
        printf "%-40s %s\n", "#{MinioRunner::System::ENV_VAR_PREFIX}#{key.upcase}", value
      end
  end
end
