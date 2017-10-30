
require "spec_helper"

RSpec.describe Teams::Team do
  it "can be initialized without values" do
    nil_team = Teams::Team.new
    expect(nil_team.id).to eq(nil)
    expect(nil_team.name).to eq(nil)
  end

  it "takes an id and a name" do
    team = Teams::Team.new(3, "seven")
    expect(team.id).to eq(3)
    expect(team.name).to eq("seven")
  end

  it "is persisted iff an id is set" do
    nil_team = Teams::Team.new
    expect(nil_team.persisted?).to eq(false)

    team = Teams::Team.new(3, "seven")
    expect(team.persisted?).to eq(true)
  end
end

