# frozen_string_literal: true

require "faraday"
require "json"

module PicqerAPI
  class Resource
    # Picqer pages at 100 rows via `offset`.
    PAGE_SIZE = 100

    # Page ceiling. Reaching it raises rather than truncating.
    MAX_PAGES = 100

    # 400 with this code means the endpoint is not available to a
    # fulfilment-scoped key, not that the request was malformed.
    NOT_ACCESSIBLE_ERROR_CODE = 31

    DEFAULT_RETRY_AFTER = 60

    attr_reader :client

    def initialize(client)
      @client = client
    end

    private

    def get_request(path, params: {}, headers: {})
      request { client.connection.get(path, params, headers) }
    end

    def post_request(path, body: {}, headers: {})
      request { client.connection.post(path, body, headers) }
    end

    def put_request(path, body: {}, headers: {})
      request { client.connection.put(path, body, headers) }
    end

    def delete_request(path, headers: {})
      request { client.connection.delete(path, nil, headers) }
    end

    def request
      with_rate_limit_retry do
        handle_response(yield)
      rescue Faraday::Error => error
        raise_transport_error(error)
      end
    end

    # A timeout or a dropped connection is not a Picqer error and carries no
    # status. It reaches the caller as an APIError so one rescue covers every
    # failure of a call.
    def raise_transport_error(error)
      wrapped = APIError.new(
        "Network request failed: #{error.message}",
        response: error.response,
        status_code: error.response_status
      )

      raise wrapped, cause: error
    end

    # Walks `offset` until a short page arrives. Every caller that needs the whole
    # list must paginate: an unfiltered GET /returns returns only the first 100.
    #
    # A truncated list that looks complete is the failure this gem exists to
    # prevent, so hitting the page guard raises rather than returning what was
    # collected so far. Narrow the query, or page by hand with `offset`.
    def paginate(path, params: {})
      rows = []
      offset = params[:offset].to_i

      MAX_PAGES.times do
        page = get_request(path, params: params.merge(offset: offset))
        raise APIError, "expected a list from #{path}, got #{page.class}" unless page.is_a?(Array)

        rows.concat(page)
        return rows if page.length < PAGE_SIZE

        offset += PAGE_SIZE
      end

      raise PaginationError,
        "#{path} still had rows after #{MAX_PAGES} pages (#{rows.length} collected). " \
        "Narrow the query with a supported filter, or page by hand with `offset`."
    end

    def with_rate_limit_retry
      attempts = 0

      begin
        yield
      rescue RateLimitError => error
        attempts += 1
        raise error if attempts > client.max_retries

        client.sleep_for(error.retry_after || DEFAULT_RETRY_AFTER)
        retry
      end
    end

    def handle_response(response)
      client.rate_limit = RateLimit.from_headers(response.headers)
      body = parse_body(response.body)
      return body if response.status.between?(200, 299)

      raise error_for(response, body)
    end

    def error_for(response, body)
      error_code = extract_error_code(body)
      error_class, prefix = error_mapping(response.status, error_code)
      rate_limit = RateLimit.from_headers(response.headers)

      error_class.new(
        "#{prefix} (HTTP #{response.status}, error_code #{error_code || "none"}): #{extract_error_message(body)}",
        response: response,
        status_code: response.status,
        error_code: error_code,
        retry_after: rate_limit&.retry_after,
        rate_limit: rate_limit
      )
    end

    def error_mapping(status, error_code)
      return [NotAccessibleError, "Function not accessible for this API key"] if error_code == NOT_ACCESSIBLE_ERROR_CODE

      case status
      when 400, 422 then [ValidationError, "Invalid request"]
      when 401, 403 then [AuthenticationError, "Authentication failed"]
      when 404 then [NotFoundError, "Resource not found"]
      when 429 then [RateLimitError, "Rate limited"]
      when 500..599 then [ServerError, "Server error"]
      else [APIError, "API error"]
      end
    end

    def parse_body(body)
      return body unless body.is_a?(String)

      JSON.parse(body)
    rescue JSON::ParserError
      body
    end

    # Picqer error bodies are {"error": true, "error_code": N, "error_message": "..."}.
    # Messages are Dutch and change; the code is the contract.
    def extract_error_code(body)
      return unless body.is_a?(Hash)

      Integer(body["error_code"] || body[:error_code], exception: false)
    end

    def extract_error_message(body)
      case body
      when Hash
        [body["error_message"], body[:error_message], body["message"], body[:message]]
          .find { |value| value.is_a?(String) } || "Unknown error"
      when String then body
      else "Unknown error"
      end
    end

    # Unsupported filters are silently ignored and the full list comes back with a
    # 200, so an unrecognised filter must fail here rather than return everything.
    def assert_supported_filters!(filters, supported)
      unknown = filters.keys.map(&:to_sym) - supported.to_a

      return if unknown.empty?

      raise ArgumentError,
        "unsupported filter(s) #{unknown.join(", ")}; Picqer ignores unknown filters and returns the full list. " \
        "Supported: #{supported.to_a.join(", ")}"
    end
  end
end
