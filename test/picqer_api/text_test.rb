# frozen_string_literal: true

require "test_helper"

module PicqerAPI
  class TextTest < TestCase
    def test_truncates_at_the_varchar_255_boundary
      assert_equal 254, Text.sanitize("a" * 254).length
      assert_equal 255, Text.sanitize("a" * 256).length
    end

    def test_counts_characters_not_bytes
      assert_equal 255, Text.sanitize("é" * 255).length
      assert_equal 255, Text.sanitize("漢" * 255).length
    end

    def test_strips_four_byte_characters_without_leaving_double_spaces
      assert_equal "Anna Smith", Text.sanitize("Anna 😀 Smith")
      assert_equal "RMA-123", Text.sanitize("RMA-123 😀")
    end

    def test_allows_the_longer_text_limit_for_log_messages
      assert_equal 65_535, Text.sanitize_log_message("a" * 70_000).length
    end

    def test_reports_whether_picqer_would_alter_the_value
      assert Text.truncated?("a" * 256)
      assert Text.truncated?("hi 😀")
      refute Text.truncated?("RMA-12345")
    end

    def test_leaves_non_strings_alone
      assert_equal 17_267, Text.sanitize(17_267)
      assert_nil Text.sanitize(nil)
    end
  end
end
