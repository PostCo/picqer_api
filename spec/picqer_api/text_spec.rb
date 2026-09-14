# frozen_string_literal: true

RSpec.describe PicqerAPI::Text do
  it "truncates at the varchar(255) boundary" do
    expect(described_class.sanitize("a" * 254).length).to eq(254)
    expect(described_class.sanitize("a" * 256).length).to eq(255)
  end

  it "counts characters, not bytes" do
    expect(described_class.sanitize("é" * 255).length).to eq(255)
    expect(described_class.sanitize("漢" * 255).length).to eq(255)
  end

  it "strips four-byte characters utf8mb3 cannot store, without leaving double spaces" do
    expect(described_class.sanitize("Anna 😀 Smith")).to eq("Anna Smith")
    expect(described_class.sanitize("RMA-123 😀")).to eq("RMA-123")
  end

  it "allows the longer text limit for log messages" do
    expect(described_class.sanitize_log_message("a" * 70_000).length).to eq(65_535)
  end

  it "reports whether Picqer would alter the value" do
    expect(described_class).to be_truncated("a" * 256)
    expect(described_class).to be_truncated("hi 😀")
    expect(described_class).not_to be_truncated("RMA-12345")
  end

  it "leaves non-strings alone" do
    expect(described_class.sanitize(17_267)).to eq(17_267)
    expect(described_class.sanitize(nil)).to be_nil
  end
end
