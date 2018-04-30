require 'spec_helper'

RSpec.describe "it is set up" do
  it "is a failure" do
    expect(1).to eq(0)
  end

  it "is a success" do
    expect(1).to eq(1)
  end
end
