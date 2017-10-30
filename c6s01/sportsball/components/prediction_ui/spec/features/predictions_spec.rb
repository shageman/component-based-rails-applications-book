
RSpec.describe "the prediction process", :type => :feature do
  before :each do
    team1 = create_team name: "UofL"
    team2 = create_team name: "UK"

    create_game first_team_id: team1.id, second_team_id: team2.id, winning_team: 1
    create_game first_team_id: team2.id, second_team_id: team1.id, winning_team: 2
    create_game first_team_id: team2.id, second_team_id: team1.id, winning_team: 2
  end

  it "get a new prediction" do
    visit "/prediction_ui/prediction/new"

    click_link "Predictions"

    select "UofL", from: "First team"
    select "UK", from: "Second team"
    click_button "What is it going to be"

    expect(page).to have_content "the winner will be UofL"
  end
end

