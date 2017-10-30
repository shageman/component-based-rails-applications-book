
RSpec.describe "teams admin", :type => :feature do
  it "allows for the management of teams" do
    visit "/teams_admin/teams"

    click_link "New Team"

    fill_in "Name", with: "UofL"
    click_on "Create Team"

    click_link "New Team"

    fill_in "Name", with: "UK"
    click_on "Create Team"

    expect(page).to have_content "UofL"
    expect(page).to have_content "UK"
  end
end

