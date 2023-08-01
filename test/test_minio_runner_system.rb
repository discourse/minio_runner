# frozen_string_literal: true

require "test_helper"

class TestMinioRunnerSystem < Minitest::Test
  def test_that_it_can_get_configurable_env_vars
    mock_env("MINIO_RUNNER_INSTALL_DIR" => "~/testdir") do
      assert_equal(MinioRunner::System.env(:install_dir), "~/testdir")
    end
  end

  def test_that_it_errors_for_invalid_env_vars
    assert_raises(MinioRunner::System::InvalidEnvVar) { MinioRunner::System.env(:invalid_env_var) }
  end
end
