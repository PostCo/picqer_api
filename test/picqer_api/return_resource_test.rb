# frozen_string_literal: true

require "test_helper"

module PicqerAPI
  class ReturnResourceTest < TestCase
    def test_create_posts_the_payload_and_returns_the_response_object
      stub_picqer(:post, "returns", status: 201,
        body: {idreturn: 6943828, returnid: "R2026-1030",
               returned_products: [{idreturn_product: 11196084, idproduct: 51654384}]})

      result = client.returns.create({idreturn_status: 17267, reference: "RMA-12345"})

      assert_equal 6943828, result.idreturn
      assert_equal 11196084, result.returned_products.first.idreturn_product
      assert_requested(:post, "#{BASE_URL}/returns",
        body: JSON.dump({"idreturn_status" => 17267, "reference" => "RMA-12345"}))
    end

    def test_create_strips_non_bmp_characters_and_truncates_the_varchar_255_fields
      stub_picqer(:post, "returns", status: 201, body: {idreturn: 1})

      client.returns.create({idreturn_status: 17267, name: "Anna 😀 Smith", address: "a" * 300})

      assert_requested(:post, "#{BASE_URL}/returns") { |request|
        body = JSON.parse(request.body)
        body["name"] == "Anna Smith" && body["address"].length == 255
      }
    end

    def test_create_leaves_the_payload_alone_when_sanitizing_is_turned_off
      stub_picqer(:post, "returns", status: 201, body: {idreturn: 1})

      client.returns.create({idreturn_status: 17267, name: "Anna 😀 Smith"}, sanitize: false)

      assert_requested(:post, "#{BASE_URL}/returns") { |request|
        JSON.parse(request.body)["name"] == "Anna 😀 Smith"
      }
    end

    def test_create_does_not_touch_non_string_fields
      stub_picqer(:post, "returns", status: 201, body: {idreturn: 1})

      client.returns.create({idreturn_status: 17267, returned_products: [{idproduct: 1, idreturn_reason: 13593}]})

      assert_requested(:post, "#{BASE_URL}/returns") { |request|
        JSON.parse(request.body)["returned_products"].first["idproduct"] == 1
      }
    end

    def test_list_rejects_filters_picqer_would_silently_ignore
      error = assert_raises(ArgumentError) { client.returns.list(reference: "RMA-12345") }

      assert_match(/unsupported filter\(s\) reference/, error.message)
      assert_raises(ArgumentError) { client.returns.list(idorder: 274848164) }
    end

    def test_list_allows_the_filters_picqer_honours
      stub_picqer(:get, "returns", query: {"status" => "completed"}, body: [{idreturn: 1}])

      assert_equal 1, client.returns.list(status: "completed").first.idreturn
    end

    def test_search_passes_the_fuzzy_query_through_and_paginates
      stub_picqer(:get, "returns", query: {"search" => "RMA-12345", "offset" => "0"},
        body: [{idreturn: 1, reference: "RMA-12345"}, {idreturn: 2, reference: "RMA-12345-B"}])

      # Deliberately returns both: the caller verifies `reference` exactly and
      # decides what zero, one or several matches mean.
      assert_equal [1, 2], client.returns.search("RMA-12345").map(&:idreturn)
    end

    def test_add_log_posts_a_status_change_and_truncates_the_message_to_the_text_column
      stub_picqer(:post, "returns/1/logs", status: 201, body: {idreturn_log: 9})

      client.returns.add_log(1, idreturn_status: 17272, message: "a" * 70_000)

      assert_requested(:post, "#{BASE_URL}/returns/1/logs") { |request|
        body = JSON.parse(request.body)
        body["idreturn_status"] == 17272 && body["message"].length == 65_535
      }
    end

    def test_receive_surfaces_the_fulfilment_capability_gap
      stub_picqer(:post, "returns/1/receive", status: 400,
        body: {error: true, error_code: 31, error_message: "Function not accessible for fulfilment"})

      assert_raises(NotAccessibleError) do
        client.returns.receive(1, idwarehouse: 13910,
          returned_products: [{idreturn_product: 2, status: "added_to_stock"}])
      end
    end

    def test_delete_returned_product_deletes_a_line
      stub_picqer(:delete, "returns/1/returned_products/2", status: 204, body: "")

      assert client.returns.delete_returned_product(1, 2)
    end
  end
end
