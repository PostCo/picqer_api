# frozen_string_literal: true

require "test_helper"

class PicqerAPITest < PicqerAPI::TestCase
  def test_has_a_version_number
    assert_match(/\A\d+\.\d+\.\d+\z/, PicqerAPI::VERSION)
  end

  def test_loads_without_rails_or_zeitwerk
    assert_nil defined?(Rails)
    assert_nil defined?(Zeitwerk)
  end
end
