
require "spec_helper"

RSpec.describe "games admin", :type => :feature do
  before :each do
    @team1 = create_team name: "UofL"
    @team2 = create_team name: "UK"
  end

  it "allows for the management of games" do
    visit "/app_component/games"

    click_link "New Game"

    fill_in "First team", with: @team1.id
    fill_in "Second team", with: @team2.id
    fill_in "Winning team", with: 1
    fill_in "First team score", with: 2
    fill_in "Second team score", with: 1
    fill_in "Location", with: "Home"

    click_on "Create Game"

    expect(page).to have_content "UofL"
  end
end

