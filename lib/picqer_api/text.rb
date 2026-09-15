# frozen_string_literal: true

module PicqerAPI
  # Picqer stores every string field on a return in a utf8mb3 varchar(255) column
  # and truncates silently at 201 Created, so the value read back can differ from
  # the value sent with no error anywhere. Four-byte characters (emoji) are
  # stripped rather than truncated, which mangles surrounding text.
  #
  # Sanitize before sending so the caller controls the loss, and use
  # {as_stored_by_picqer} to predict what an unsanitized value becomes.
  module Text
    MAX_LENGTH = 255
    # logs.message is a text column, not varchar(255).
    MAX_LOG_MESSAGE_LENGTH = 65_535

    # Characters outside the Basic Multilingual Plane, which utf8mb3 cannot store.
    NON_BMP = /[\u{10000}-\u{10FFFF}]/

    # A run of them plus at most one space on either side. Measured: Picqer drops
    # the characters and keeps both spaces, so "Anna <emoji> Smith" is stored as
    # "Anna  Smith". Removing one adjacent space avoids that without touching
    # whitespace elsewhere in the value.
    NON_BMP_RUN = /[[:blank:]]?#{NON_BMP}+[[:blank:]]?/

    module_function

    # What to send: the non-BMP characters removed without leaving a gap, then
    # truncated to the column width. Picqer stores this unchanged, so a read-back
    # comparison against the value you sent is exact.
    def sanitize(value, limit: MAX_LENGTH)
      return value unless value.is_a?(String)

      value.gsub(NON_BMP_RUN) { |match| (match.start_with?(" ") && match.end_with?(" ")) ? " " : "" }[0, limit]
    end

    def sanitize_log_message(value)
      sanitize(value, limit: MAX_LOG_MESSAGE_LENGTH)
    end

    # What Picqer itself would store for a value sent raw: the same characters
    # dropped, but the spaces around them kept, then a silent truncation.
    # Measured against the live API, not read from the documentation.
    def as_stored_by_picqer(value, limit: MAX_LENGTH)
      return value unless value.is_a?(String)

      value.gsub(NON_BMP, "")[0, limit]
    end

    # True when Picqer would alter the value on write.
    def truncated?(value, limit: MAX_LENGTH)
      value.is_a?(String) && as_stored_by_picqer(value, limit: limit) != value
    end
  end
end
