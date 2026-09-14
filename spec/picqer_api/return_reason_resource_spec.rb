# frozen_string_literal: true

RSpec.describe PicqerAPI::ReturnReasonResource do
  it "returns the account's reasons" do
    stub_picqer(:get, "return_reasons", body: [{idreturn_reason: 13593, name: "Wrong product"}])

    expect(build_client.return_reasons.all.first.idreturn_reason).to eq(13593)
  end
end
