# frozen_string_literal: true

RSpec.describe PicqerAPI::HookResource do
  let(:client) { build_client }

  it "creates a hook with a secret" do
    request = stub_picqer(:post, "hooks", status: 201, body: {idhook: 67982, active: true})

    hook = client.hooks.create(name: "PostCo", event: "returns.status_changed",
      address: "https://example.test/hooks", secret: "s3cret")

    expect(hook.idhook).to eq(67982)
    expect(request.with { |req| JSON.parse(req.body)["secret"] == "s3cret" }).to have_been_made
  end

  it "lists the hooks the key owns" do
    stub_picqer(:get, "hooks", body: [{idhook: 67982, active: false}])

    expect(build_client.hooks.all.first.active).to be(false)
  end

  it "treats DELETE as a deactivation and can reactivate" do
    stub_picqer(:delete, "hooks/67982", status: 204, body: "")
    stub_picqer(:post, "hooks/67982/reactivate", status: 200, body: {idhook: 67982, active: true})

    expect(client.hooks.deactivate(67982)).to be(true)
    expect(client.hooks.reactivate(67982).active).to be(true)
  end
end
