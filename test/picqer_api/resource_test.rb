# frozen_string_literal: true

require "test_helper"

module PicqerAPI
  class ResourceTest < TestCase
    def test_raises_not_accessible_error_for_error_code_31_regardless_of_the_400_status
      stub_picqer(:get, "warehouses", status: 400,
        body: {error: true, error_code: 31, error_message: "Function not accessible for fulfilment"})

      error = assert_raises(NotAccessibleError) { client.warehouses.all }

      assert_equal 31, error.error_code
      assert_equal 400, error.status_code
    end

    def test_raises_validation_error_for_a_400_and_keeps_the_dutch_message_and_code
      stub_picqer(:post, "returns", status: 400,
        body: {error: true, error_code: 5, error_message: 'Veld "idreturn status" is verplicht.'})

      error = assert_raises(ValidationError) { client.returns.create({}) }

      assert_equal 5, error.error_code
      assert_includes error.message, "verplicht"
    end

    def test_raises_not_found_error_for_a_404
      stub_picqer(:get, "returns/1", status: 404, body: {error: true, error_code: 20, error_message: "not found"})

      assert_raises(NotFoundError) { client.returns.find(1) }
    end

    def test_raises_authentication_error_for_a_401
      stub_picqer(:get, "warehouses", status: 401, body: {error: true, error_message: "Unauthorized"})

      assert_raises(AuthenticationError) { client.warehouses.all }
    end

    def test_raises_server_error_for_a_500
      stub_picqer(:get, "warehouses", status: 500, body: {error: true, error_message: "Server error"})

      assert_raises(ServerError) { client.warehouses.all }
    end

    def test_retries_once_on_429_honouring_retry_after_then_succeeds
      stub_request(:get, "#{BASE_URL}/warehouses?offset=0").to_return(
        {status: 429, body: JSON.dump({error: true, error_message: "Rate limited"}),
         headers: {"Content-Type" => "application/json", "Retry-After" => "2"}},
        {status: 200, body: JSON.dump([{idwarehouse: 13910}]), headers: {"Content-Type" => "application/json"}}
      )

      slept = []
      client = build_client(sleeper: ->(seconds) { slept << seconds })

      assert_equal 13910, client.warehouses.all.first.idwarehouse
      assert_equal [2], slept
    end

    def test_gives_up_after_max_retries_and_exposes_retry_after
      stub_picqer(:get, "warehouses", status: 429,
        body: {error: true, error_message: "Rate limited"}, headers: {"Retry-After" => "30"})

      error = assert_raises(RateLimitError) { build_client(max_retries: 0).warehouses.all }

      assert_equal 30, error.retry_after
    end

    def test_walks_offset_until_a_short_page_arrives
      stub_picqer(:get, "warehouses", query: {"offset" => "0"}, body: Array.new(100) { |index| {idwarehouse: index} })
      stub_picqer(:get, "warehouses", query: {"offset" => "100"}, body: [{idwarehouse: 100}])

      assert_equal 101, client.warehouses.all.length
    end
  end
end
