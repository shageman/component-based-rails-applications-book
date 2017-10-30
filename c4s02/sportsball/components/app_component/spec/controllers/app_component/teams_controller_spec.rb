
RSpec.describe AppComponent::TeamsController, :type => :controller do
  routes { AppComponent::Engine.routes }

  let(:valid_attributes) { new_team.as_json }
  let(:invalid_attributes) { new_team.tap { |g| g.name = nil }.as_json }
  let(:valid_session) { {} }

  describe "GET index" do
    it "assigns all teams as @teams" do
      team = create_team
      get :index, params: {}, session: valid_session
      expect(assigns(:teams)).to eq [team]
    end

    describe "view" do
      render_views

      it "renders a list of teams" do
        create_team name: "myteam x"
        create_team name: "myteam x"

        get :index, params: {}, session: valid_session

        assert_select "tr>td", :text => "myteam x", :count => 2
      end
    end
  end

  describe "GET new" do
    it "assigns a new team as @team" do
      get :new, params: {}, session: valid_session
      expect(assigns(:team)).to be_a_new AppComponent::Team
    end

    describe "view" do
      render_views

      it "renders new team form" do
        get :new, params: {}, session: valid_session

        assert_select "form[action=?][method=?]", teams_path, "post" do
          assert_select "input#team_name[name=?]", "team[name]"
        end
      end
    end
  end

  describe "GET edit" do
    it "assigns the requested team as @team" do
      team = create_team
      get :edit, params: {:id => team.to_param}, session: valid_session
      expect(assigns(:team)).to eq team
    end

    describe "view" do
      render_views

      it "renders the edit team form" do
        team = create_team
        get :edit, params: {:id => team.to_param}, session: valid_session

        assert_select "form[action=?][method=?]", team_path(team), "post" do
          assert_select "input#team_name[name=?]", "team[name]"
        end
      end
    end
  end

  describe "POST create" do
    describe "with valid params" do
      it "creates a new AppComponent::Team" do
        expect {
          post :create, params: {:team => valid_attributes}, session: valid_session
        }.to change(AppComponent::Team, :count).by 1
      end

      it "assigns a newly created team as @team" do
        post :create, params: {:team => valid_attributes}, session: valid_session
        expect(assigns(:team)).to be_a AppComponent::Team
        expect(assigns(:team)).to be_persisted
      end

      it "redirects to the index" do
        post :create, params: {:team => valid_attributes}, session: valid_session
        expect(response).to redirect_to teams_path
      end
    end

    describe "with invalid params" do
      it "assigns a newly created but unsaved team as @team" do
        post :create, params: {:team => invalid_attributes}, session: valid_session
        expect(assigns(:team)).to be_a_new AppComponent::Team
      end

      it "re-renders the new template" do
        post :create, params: {:team => invalid_attributes}, session: valid_session
        expect(response).to render_template "new"
      end
    end
  end

  describe "PUT update" do
    describe "with valid params" do
      let(:new_attributes) {
        {name: "new team name"}
      }

      it "updates the requested team" do
        team = create_team
        put :update, params: {:id => team.to_param, :team => new_attributes}, session: valid_session
        team.reload
        expect(assigns(:team).name).to eq "new team name"
      end

      it "assigns the requested team as @team" do
        team = create_team
        put :update, params: {:id => team.to_param, :team => valid_attributes}, session: valid_session
        expect(assigns(:team)).to eq team
      end

      it "redirects to the index" do
        team = create_team
        put :update, params: {:id => team.to_param, :team => valid_attributes}, session: valid_session
        expect(response).to redirect_to teams_path
      end
    end

    describe "with invalid params" do
      it "assigns the team as @team" do
        team = create_team
        put :update, params: {:id => team.to_param, :team => invalid_attributes}, session: valid_session
        expect(assigns(:team)).to eq team
      end

      it "re-renders the edit template" do
        team = create_team
        put :update, params: {:id => team.to_param, :team => invalid_attributes}, session: valid_session
        expect(response).to render_template "edit"
      end
    end
  end

  describe "DELETE destroy" do
    it "destroys the requested team" do
      team = create_team
      expect {
        delete :destroy, params: {:id => team.to_param}, session: valid_session
      }.to change(AppComponent::Team, :count).by -1
    end

    it "redirects to the teams list" do
      team = create_team
      delete :destroy, params: {:id => team.to_param}, session: valid_session
      expect(response).to redirect_to teams_url
    end
  end
end

