# frozen_string_literal: true

require "bundler/gem_tasks"
require "rake/testtask"

Rake::TestTask.new(:test) do |t|
  t.libs << "test"
  t.libs << "lib"
  t.test_files = FileList["test/**/test_*.rb"]
end

task default: :test

namespace :minio_runner do
  task :list_configurable_env do
    require "bundler/setup"
    require "minio_runner"

    puts "These are the configurable environment variables for MinioRunner:"
    puts "-" * 20

    MinioRunner::Config::CONFIGURABLE_ENV_VARS
      .sort_by { |key| key }
      .each do |key, value|
        printf "%-40s %s\n", "#{MinioRunner::System::ENV_VAR_PREFIX}#{key.upcase}", value
      end
  end
end
