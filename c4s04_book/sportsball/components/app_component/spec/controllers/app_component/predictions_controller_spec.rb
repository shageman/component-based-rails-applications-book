
RSpec.describe AppComponent::PredictionsController, :type => :controller do
  routes { AppComponent::Engine.routes }

  before do
    @team1 = create_team
    @team2 = create_team
  end

  describe "GET new" do
    it "assigns all teams as @teams" do
      get :new, params: {}, session: {}
      expect(assigns(:teams)).to eq [@team1, @team2]
    end
  end

  describe "POST create" do
    it "assigns a prediction as @prediction" do
      post :create,
           params: {first_team: {id: @team1.id}, second_team: {id: @team2.id}},
           session: {}

      prediction = assigns(:prediction)
      expect(prediction).to be_a ::Predictor::Prediction
      expect(prediction.first_team).to eq @team1
      expect(prediction.second_team).to eq @team2
    end
  end
end


