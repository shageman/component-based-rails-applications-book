
require "spec_helper"

RSpec.describe "nav entry" do
  it "points at the list of games" do
    entry = GamesAdmin.nav_entry
    expect(entry[:name]).to eq "Games"
    expect(entry[:link].call).to eq "/games_admin/games"
  end
end

