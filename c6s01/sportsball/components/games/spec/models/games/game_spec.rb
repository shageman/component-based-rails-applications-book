RSpec.describe Games::Game do
  it { should validate_presence_of(:date) }
  it { should validate_presence_of(:location) }
  it { should validate_presence_of(:first_team_id) }
  it { should validate_presence_of(:second_team_id) }
  it { should validate_presence_of(:winning_team) }
  it { should validate_presence_of(:first_team_score) }
  it { should validate_presence_of(:second_team_score) }
end

