# frozen_string_literal: true

require "test_helper"

class TestMinioRunner < Minitest::Test
  def teardown
    MinioRunner.reset_config!
  end

  def test_that_it_has_a_version_number
    refute_nil ::MinioRunner::VERSION
  end

  def test_it_can_yield_config
    assert(MinioRunner.config != nil)
    MinioRunner.config { |config| assert(config != nil) }
  end
end
