# frozen_string_literal: true

RSpec.describe PicqerAPI::Resource do
  let(:client) { build_client }

  describe "error mapping" do
    it "raises NotAccessibleError for error_code 31 regardless of the 400 status" do
      stub_picqer(:get, "warehouses", status: 400,
        body: {error: true, error_code: 31, error_message: "Function not accessible for fulfilment"})

      expect { client.warehouses.all }.to raise_error(PicqerAPI::NotAccessibleError) { |error|
        expect(error.error_code).to eq(31)
        expect(error.status_code).to eq(400)
      }
    end

    it "raises ValidationError for a 400 and keeps the Dutch message and code" do
      stub_picqer(:post, "returns", status: 400,
        body: {error: true, error_code: 5, error_message: 'Veld "idreturn status" is verplicht.'})

      expect { client.returns.create({}) }.to raise_error(PicqerAPI::ValidationError) { |error|
        expect(error.error_code).to eq(5)
        expect(error.message).to include("verplicht")
      }
    end

    it "raises NotFoundError for a 404" do
      stub_picqer(:get, "returns/1", status: 404, body: {error: true, error_code: 20, error_message: "not found"})

      expect { client.returns.find(1) }.to raise_error(PicqerAPI::NotFoundError)
    end

    it "raises AuthenticationError for a 401" do
      stub_picqer(:get, "warehouses", status: 401, body: {error: true, error_message: "Unauthorized"})

      expect { client.warehouses.all }.to raise_error(PicqerAPI::AuthenticationError)
    end

    it "raises ServerError for a 500" do
      stub_picqer(:get, "warehouses", status: 500, body: {error: true, error_message: "Server error"})

      expect { client.warehouses.all }.to raise_error(PicqerAPI::ServerError)
    end
  end

  describe "rate limiting" do
    it "retries once on 429, honouring Retry-After, then succeeds" do
      stub_request(:get, "#{ClientHelpers::BASE_URL}/warehouses?offset=0")
        .to_return(
          {status: 429, body: JSON.dump({error: true, error_message: "Rate limited"}),
           headers: {"Content-Type" => "application/json", "Retry-After" => "2"}},
          {status: 200, body: JSON.dump([{idwarehouse: 13910}]), headers: {"Content-Type" => "application/json"}}
        )

      slept = []
      client = build_client(sleeper: ->(seconds) { slept << seconds })

      expect(client.warehouses.all.first.idwarehouse).to eq(13910)
      expect(slept).to eq([2])
    end

    it "gives up after max_retries and exposes retry_after" do
      stub_picqer(:get, "warehouses", status: 429,
        body: {error: true, error_message: "Rate limited"}, headers: {"Retry-After" => "30"})

      client = build_client(max_retries: 0)

      expect { client.warehouses.all }.to raise_error(PicqerAPI::RateLimitError) { |error|
        expect(error.retry_after).to eq(30)
      }
    end
  end

  describe "pagination" do
    it "walks offset until a short page arrives" do
      first_page = Array.new(100) { |index| {idwarehouse: index} }
      stub_picqer(:get, "warehouses", query: {"offset" => "0"}, body: first_page)
      stub_picqer(:get, "warehouses", query: {"offset" => "100"}, body: [{idwarehouse: 100}])

      expect(build_client.warehouses.all.length).to eq(101)
    end
  end
end
