# frozen_string_literal: true

require "base64"
require "faraday"

module PicqerAPI
  class Client
    # Every Picqer account is its own subdomain. There is no sandbox host: a
    # developer account is an ordinary account on its own subdomain.
    BASE_URL_TEMPLATE = "https://%<subdomain>s.picqer.com/api/v1/"

    # Picqer rejects requests without a User-Agent.
    DEFAULT_USER_AGENT = "PicqerAPI Ruby gem (https://github.com/PostCo/picqer_api)"

    attr_reader :subdomain, :api_key, :user_agent, :adapter, :max_retries, :rate_limit

    # @param subdomain [String] the Picqer account subdomain. For a fulfilment
    #   provider this is the provider's subdomain, not the retailer's, and it is
    #   shared by every customer under that provider. It is not a unique key.
    # @param api_key [String] sent as the HTTP Basic username; the password is ignored.
    #   A customer-scoped key silently limits everything to that customer.
    # @param max_retries [Integer] retries on 429 only, honouring Retry-After.
    def initialize(subdomain:, api_key:, user_agent: DEFAULT_USER_AGENT, adapter: Faraday.default_adapter,
      max_retries: 1, sleeper: ->(seconds) { sleep(seconds) })
      raise ArgumentError, "subdomain is required" if subdomain.to_s.strip.empty?
      raise ArgumentError, "api_key is required" if api_key.to_s.strip.empty?

      @subdomain = subdomain
      @api_key = api_key
      @user_agent = user_agent
      @adapter = adapter
      @max_retries = max_retries
      @sleeper = sleeper
    end

    def base_url
      format(BASE_URL_TEMPLATE, subdomain: subdomain)
    end

    def connection
      @connection ||= Faraday.new do |connection|
        connection.url_prefix = base_url
        connection.headers["Authorization"] = "Basic #{Base64.strict_encode64("#{api_key}:")}"
        connection.headers["Accept"] = "application/json"
        connection.headers["User-Agent"] = user_agent
        connection.request :json
        connection.response :json, content_type: /\bjson/
        connection.adapter adapter
      end
    end

    def returns
      @returns ||= ReturnResource.new(self)
    end

    def return_statuses
      @return_statuses ||= ReturnStatusResource.new(self)
    end

    def return_reasons
      @return_reasons ||= ReturnReasonResource.new(self)
    end

    def warehouses
      @warehouses ||= WarehouseResource.new(self)
    end

    def products
      @products ||= ProductResource.new(self)
    end

    def orders
      @orders ||= OrderResource.new(self)
    end

    def hooks
      @hooks ||= HookResource.new(self)
    end

    # Rate-limit headers from the most recent response, or nil before the first one.
    attr_writer :rate_limit

    def sleep_for(seconds)
      @sleeper.call(seconds)
    end
  end
end
