
RSpec.describe "nav entry" do
  it "points at the list of teams" do
    entry = TeamsAdmin.nav_entry
    expect(entry[:name]).to eq "Teams"
    expect(entry[:link].call).to eq "/teams_admin/teams"
  end
end

