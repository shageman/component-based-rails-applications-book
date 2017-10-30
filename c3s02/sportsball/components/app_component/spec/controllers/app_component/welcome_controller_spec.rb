
RSpec.describe AppComponent::WelcomeController, :type => :controller do
  routes { AppComponent::Engine.routes }

  describe "GET index" do
    it "returns http success" do
      get :show
      expect(response).to have_http_status(:success)
    end
  end
end

