# frozen_string_literal: true

module PicqerAPI
  # Snapshot of the rate-limit headers on the most recent response.
  # Picqer allows 500 requests per minute per API key.
  class RateLimit
    attr_reader :limit, :remaining, :retry_after

    def self.from_headers(headers)
      return if headers.nil?

      new(
        limit: integer_or_nil(headers["x-ratelimit-limit"]),
        remaining: integer_or_nil(headers["x-ratelimit-remaining"]),
        retry_after: integer_or_nil(headers["retry-after"])
      )
    end

    def self.integer_or_nil(value)
      Integer(value, exception: false)
    end
    private_class_method :integer_or_nil

    def initialize(limit: nil, remaining: nil, retry_after: nil)
      @limit = limit
      @remaining = remaining
      @retry_after = retry_after
    end

    def exhausted?
      !remaining.nil? && remaining <= 0
    end

    def to_h
      {limit: limit, remaining: remaining, retry_after: retry_after}
    end
  end
end
