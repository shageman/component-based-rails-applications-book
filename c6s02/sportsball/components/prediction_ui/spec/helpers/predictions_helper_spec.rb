
RSpec.describe PredictionUi::PredictionsHelper, :type => :helper do
  Named = Struct.new(:name)

  it "returns a nice prediction text" do
    text = prediction_text(Named.new("A"), Named.new("B"), Named.new("C"))
    expect(text).to eq "In the game between A and B the winner will be C"
  end

  it "returns a winner not determined if given no winner" do
    text = prediction_text(Named.new("A"), Named.new("B"), nil)
    expect(text).to eq "Winner not determined"
  end
end

