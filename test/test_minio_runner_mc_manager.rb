# frozen_string_literal: true

require "test_helper"
require "open3"

class TestMinioRunnerMcManager < Minitest::Test
  def described_class
    MinioRunner::McManager
  end

  def setup
    MinioRunner.config.install_dir = "/tmp/minio_runner_test"
    MinioRunner.remove_install_dir
    MinioRunner::System.make_install_dir
    Spy.on(described_class, :sleep).and_return(nil)
  end

  def teardown
    Spy.teardown
    MinioRunner.reset_config!
  end

  def stub_capture3(*responses)
    queue = responses.dup
    Spy.on(Open3, :capture3).and_return { queue.shift || responses.last }
  end

  def ok(stdout = "")
    [stdout, "", make_status(true)]
  end

  def failed(stderr = "boom")
    ["", stderr, make_status(false)]
  end

  def make_status(success)
    Object.new.tap do |s|
      s.define_singleton_method(:success?) { success }
      s.define_singleton_method(:exitstatus) { success ? 0 : 1 }
    end
  end

  def test_run_mc_returns_on_success
    capture3 = stub_capture3(ok("hello"))

    out, err, st = described_class.run_mc(%w[ls local])

    assert_equal "hello", out
    assert_equal "", err
    assert st.success?
    assert_equal 1, capture3.calls.size
  end

  def test_run_mc_retries_then_succeeds
    capture3 = stub_capture3(failed("Server not initialized yet"), failed("connection refused"), ok)

    described_class.run_mc(%w[alias set local http://x u p])

    assert_equal 3, capture3.calls.size
  end

  def test_run_mc_raises_after_exhausting_retries
    stub_capture3(failed)

    assert_raises(MinioRunner::McManager::CommandError) do
      described_class.run_mc(%w[mb local/x], retries: 2)
    end
  end

  def test_run_mc_returns_status_when_allow_failure_is_true
    stub_capture3(failed("no such bucket"))

    _, _, st = described_class.run_mc(%w[ls local/missing], allow_failure: true, retries: 0)

    refute st.success?
  end

  def test_bucket_exists_returns_false_without_raising_when_bucket_missing
    stub_capture3(failed("Object does not exist"))

    refute described_class.bucket_exists?("local", "missing")
  end

  def test_bucket_exists_returns_true_when_listing_succeeds
    stub_capture3(ok("bucket contents"))

    assert described_class.bucket_exists?("local", "present")
  end

  def test_set_alias_raises_on_persistent_failure
    stub_capture3(failed("Server not initialized yet"))

    assert_raises(MinioRunner::McManager::CommandError) do
      described_class.set_alias("local", "http://localhost:9000")
    end
  end

  def test_set_alias_recovers_after_transient_failure
    capture3 = stub_capture3(failed("Server not initialized yet"), ok)

    described_class.set_alias("local", "http://localhost:9000")

    assert_equal 2, capture3.calls.size
  end

  def test_create_bucket_skips_when_bucket_exists
    capture3 = stub_capture3(ok)

    described_class.create_bucket("local", "existing")

    assert_equal 1, capture3.calls.size
    assert_includes capture3.calls.first.args, "ls"
  end

  def test_create_bucket_makes_bucket_when_missing
    capture3 = stub_capture3(failed("Object does not exist"), ok)

    described_class.create_bucket("local", "new-bucket")

    assert_equal 2, capture3.calls.size
    assert_includes capture3.calls.last.args, "mb"
  end

  def test_create_bucket_raises_when_mb_fails_persistently
    stub_capture3(failed("Object does not exist"), failed)

    assert_raises(MinioRunner::McManager::CommandError) do
      described_class.create_bucket("local", "doomed")
    end
  end

  def test_set_anon_raises_on_persistent_failure
    stub_capture3(failed)

    assert_raises(MinioRunner::McManager::CommandError) do
      described_class.set_anon("local", "x", "public")
    end
  end
end
