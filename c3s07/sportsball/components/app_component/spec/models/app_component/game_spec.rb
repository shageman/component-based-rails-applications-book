
RSpec.describe AppComponent::Game do
  it { should validate_presence_of :date }
  it { should validate_presence_of :location }
  it { should validate_presence_of :first_team }
  it { should validate_presence_of :second_team }
  it { should validate_presence_of :winning_team }
  it { should validate_presence_of :first_team_score }
  it { should validate_presence_of :second_team_score }

  it { should belong_to :first_team}
  it { should belong_to :second_team}
end

