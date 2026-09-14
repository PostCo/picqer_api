# frozen_string_literal: true

RSpec.describe PicqerAPI do
  it "has a version number" do
    expect(PicqerAPI::VERSION).to match(/\A\d+\.\d+\.\d+\z/)
  end

  it "loads without Rails or Zeitwerk" do
    expect(defined?(Rails)).to be_nil
    expect(defined?(Zeitwerk)).to be_nil
  end
end
