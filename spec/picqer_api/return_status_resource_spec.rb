# frozen_string_literal: true

RSpec.describe PicqerAPI::ReturnStatusResource do
  let(:client) { build_client }

  it "returns the account's statuses" do
    stub_picqer(:get, "return_statuses", body: [
      {idreturn_status: 17267, name: "Received", default: false, completed: false},
      {idreturn_status: 17268, name: "Completed", default: false, completed: true}
    ])

    expect(client.return_statuses.all.map(&:name)).to eq(["Received", "Completed"])
  end

  it "isolates the completed statuses, the only dependable marker" do
    stub_picqer(:get, "return_statuses", body: [
      {idreturn_status: 17267, name: "Received", default: false, completed: false},
      {idreturn_status: 17268, name: "Completed", default: false, completed: true}
    ])

    # `default` is not dependable: an account was observed with it set on nothing.
    expect(client.return_statuses.completed.map(&:idreturn_status)).to eq([17268])
  end
end
