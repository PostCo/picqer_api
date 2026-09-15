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

    def test_strips_four_byte_characters_without_leaving_the_gap
      assert_equal "Anna Smith", Text.sanitize("Anna 😀 Smith")
      assert_equal "RMA-123", Text.sanitize("RMA-123 😀")
      assert_equal "Smith", Text.sanitize("😀 Smith")
    end

    def test_leaves_whitespace_elsewhere_in_the_value_alone
      # Picqer keeps it, so collapsing it here would rewrite data the caller sent.
      assert_equal "12  Main St", Text.sanitize("12  Main St")
      assert_equal " padded ", Text.sanitize(" padded ")
      assert_equal "line\nbreak", Text.sanitize("line\nbreak")
    end

    def test_as_stored_by_picqer_keeps_the_gap_the_server_leaves
      # Measured against the live API: the emoji goes, both spaces stay.
      assert_equal "Anna  Smith", Text.as_stored_by_picqer("Anna 😀 Smith")
      assert_equal "TRK  999", Text.as_stored_by_picqer("TRK 😀 999")
      assert_equal 255, Text.as_stored_by_picqer("a" * 300).length
    end

    def test_a_sanitized_value_is_stable_through_picqer
      raw = "Anna 😀 Smith " + ("x" * 300)

      assert_equal Text.sanitize(raw), Text.as_stored_by_picqer(Text.sanitize(raw))
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
