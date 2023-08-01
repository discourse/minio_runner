# frozen_string_literal: true

require "test_helper"

class TestMinioRunnerConfig < Minitest::Test
  def test_that_config_can_be_defined_with_env_var_or_directly_and_overrides_default
    assert_equal(MinioRunner.config.install_dir, MinioRunner::Config::DEFAULT_INSTALL_DIR)
    MinioRunner.config.install_dir = "~/.mrun"
    assert_equal(MinioRunner.config.install_dir, "~/.mrun")

    MinioRunner.reset!
    mock_env("MINIO_RUNNER_INSTALL_DIR" => "~/.mrun2") do
      assert_equal(MinioRunner.config.install_dir, "~/.mrun2")
    end
  end
end
