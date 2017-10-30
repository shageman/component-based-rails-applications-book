
RSpec.describe "nav entry" do
  it "points at the list of games" do
    entry = PredictionUi.nav_entry
    expect(entry[:name]).to eq "Predictions"
    expect(entry[:link].call).to eq "/prediction_ui/prediction/new"
  end
end

