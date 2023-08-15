# frozen_string_literal: true

require "test_helper"

class TestMinioRunnerSystem < Minitest::Test
  def teardown
    MinioRunner.reset_config!
  end

  def described_class
    MinioRunner::System
  end

  def test_that_it_can_get_configurable_env_vars
    mock_env("MINIO_RUNNER_INSTALL_DIR" => "~/testdir") do
      assert_equal(described_class.env(:install_dir), "~/testdir")
    end
  end

  def test_that_it_errors_for_invalid_env_vars
    assert_raises(described_class::InvalidEnvVar) { described_class.env(:invalid_env_var) }
  end

  def test_that_it_creates_the_install_dir
    MinioRunner.config.install_dir = "/tmp/minio_runner_test/install"
    FileUtils.rm_rf(MinioRunner.config.install_dir)
    assert_equal(Dir.exist?(MinioRunner.config.install_dir), false)
    described_class.make_install_dir
    assert_equal(Dir.exist?(MinioRunner.config.install_dir), true)
  ensure
    FileUtils.rm_rf(MinioRunner.config.install_dir)
  end

  def test_that_it_raises_error_on_invalid_platform
    assert(described_class.valid_platform?)

    Gem::Platform.local.stub :os, "windows" do
      refute(described_class.valid_platform?)
      assert_raises(described_class::InvalidPlatform) { described_class.validate_platform }
    end
  end
end
