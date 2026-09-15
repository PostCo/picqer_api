# frozen_string_literal: true

module PicqerAPI
  class Error < StandardError
    attr_reader :response, :status_code, :error_code, :retry_after, :rate_limit

    def initialize(message = nil, response: nil, status_code: nil, error_code: nil, retry_after: nil, rate_limit: nil)
      super(message)
      @response = response
      @status_code = status_code
      @error_code = error_code
      @retry_after = retry_after
      @rate_limit = rate_limit
    end
  end

  class APIError < Error; end

  class AuthenticationError < Error; end

  # Picqer returns 400 for validation failures. The message is Dutch; branch on
  # +error_code+ (5 = field invalid or missing), never on the message text.
  class ValidationError < Error; end

  class NotFoundError < Error; end

  # 400 with error_code 31, "Function not accessible for fulfilment": the endpoint
  # exists but the customer-scoped key may not call it (for example
  # POST /returns/{id}/receive). A capability gap, not a bad request.
  class NotAccessibleError < Error; end

  class RateLimitError < Error; end

  # A list ran past the page ceiling, so what was collected is not the whole
  # list. Raised instead of returning a truncated list that looks complete.
  class PaginationError < Error; end

  class ServerError < Error; end
end
