# frozen_string_literal: true

require "test_helper"

class TestMinioBinaryManager < Minitest::Test
  def described_class
    MinioRunner::BinaryManager
  end

  def binary
    TestBinary
  end

  def setup
    MinioRunner.config.install_dir = "/tmp/minio_runner_test"
    MinioRunner.remove_install_dir
    MinioRunner::System.make_install_dir
  end

  def teardown
    MinioRunner.reset_config!
  end

  class NetworkGetStub
    class << self
      def call(url)
        if url == TestBinary.platform_binary_url
          "blah"
        elsif url == TestBinary.platform_sha256sum_url
          "binaryV20230801"
        end
      end
    end
  end

  def test_that_it_downloads_binaries_if_not_already_installed
    refute(File.exist?(TestBinary.binary_file_path))
    refute(File.exist?(TestBinary.checksum_file_path))
    refute(File.exist?(TestBinary.version_file_path))

    MinioRunner::Network.stub :get, NetworkGetStub do
      described_class.install(TestBinary)
    end

    assert(File.exist?(TestBinary.binary_file_path))
    assert(File.exist?(TestBinary.checksum_file_path))
    assert(File.exist?(TestBinary.version_file_path))
  end

  def test_that_the_downloaded_binary_is_executable
    MinioRunner::Network.stub :get, NetworkGetStub do
      described_class.install(TestBinary)
    end

    assert(File.executable?(TestBinary.binary_file_path))
  end

  def test_it_does_nothing_if_installed_and_version_cache_not_expired
    MinioRunner::Network.stub :get, NetworkGetStub do
      described_class.install(TestBinary)
    end

    download_spy = Spy.on(MinioRunner::Network, :download)
    described_class.install(TestBinary)
    refute download_spy.has_been_called?
  end

  def test_that_it_redownloads_if_installed_and_version_cache_expired
    MinioRunner::Network.stub :get, NetworkGetStub do
      described_class.install(TestBinary)
    end

    # cache is determined by the mtime of the version file
    `touch -d "2 days ago" #{TestBinary.version_file_path}`

    MinioRunner::Network.stub :get, NetworkGetStub do
      download_spy = Spy.on(MinioRunner::Network, :download)
      described_class.install(TestBinary)
      assert download_spy.has_been_called?
    end
  end
end
