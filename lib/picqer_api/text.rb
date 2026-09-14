# frozen_string_literal: true

module PicqerAPI
  # Picqer stores every string field on a return in a utf8mb3 varchar(255) column
  # and truncates silently at 201 Created, so the value read back can differ from
  # the value sent with no error anywhere. Four-byte characters (emoji) are
  # stripped rather than truncated, which mangles surrounding text.
  #
  # Sanitize before sending so the caller controls the loss.
  module Text
    MAX_LENGTH = 255
    # logs.message is a text column, not varchar(255).
    MAX_LOG_MESSAGE_LENGTH = 65_535

    # Characters outside the Basic Multilingual Plane, which utf8mb3 cannot store.
    NON_BMP = /[\u{10000}-\u{10FFFF}]/

    module_function

    # Strips non-BMP characters, collapses the whitespace their removal leaves
    # behind, and truncates to the column width.
    def sanitize(value, limit: MAX_LENGTH)
      return value unless value.is_a?(String)

      value.gsub(NON_BMP, "").gsub(/[[:space:]]+/, " ").strip[0, limit]
    end

    def sanitize_log_message(value)
      sanitize(value, limit: MAX_LOG_MESSAGE_LENGTH)
    end

    # True when Picqer would alter the value on write.
    def truncated?(value, limit: MAX_LENGTH)
      value.is_a?(String) && sanitize(value, limit: limit) != value
    end
  end
end
